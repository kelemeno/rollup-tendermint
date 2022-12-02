package commands

import (
	"context"
	"errors"
	"fmt"
	"os"
	"path/filepath"

	"github.com/spf13/cobra"

	cfg "github.com/tendermint/tendermint/config"
	tmos "github.com/tendermint/tendermint/libs/os"
	tmrand "github.com/tendermint/tendermint/libs/rand"
	tmtime "github.com/tendermint/tendermint/libs/time"
	"github.com/tendermint/tendermint/privval"
	"github.com/tendermint/tendermint/smartcontracts"
	"github.com/tendermint/tendermint/types"
)

// InitFilesCmd initializes a fresh Tendermint Core instance.
var InitFilesCmd = &cobra.Command{
	Use:       "init [full|validator|seed]",
	Short:     "Initializes a Tendermint node",
	ValidArgs: []string{"full", "validator", "seed"},
	// We allow for zero args so we can throw a more informative error
	Args: cobra.MaximumNArgs(1),
	RunE: initFiles,
}

var (
	keyType           = types.DefaultValidatorParams().PubKeyTypes[0]
	network           string
	accountPrivateKey string
	accountAddress    string
)

func init() {

	InitFilesCmd.Flags().StringVar(&network, "network", "devnet",
		"Network to deploy on: alpha-mainnet, alpha-goerli, or devnet (assumed at http://127.0.0.1:5050). If using devnet either provide keys, or launch devnet using --seed=42, and set seedkeys=1 here.")
	InitFilesCmd.MarkFlagRequired("network")

	InitFilesCmd.Flags().StringVar(&accountPrivateKey, "pkey", "0", "Specify privatekey. Not needed if --seedkeys=1. ")

	InitFilesCmd.Flags().StringVar(&accountAddress, "address", "0", "Specify address. Not needed if --seedkeys=1. ")

	InitFilesCmd.Flags().StringVar(&seedkeys, "seedkeys", "0",
		"If using devnet either provide keys (default), or launch devnet using seed=42 and set --seedkeys=1.")

}

func initFiles(cmd *cobra.Command, args []string) error {
	if len(args) == 0 {
		return errors.New("must specify a node type: tendermint init [validator|full|seed]")
	}
	config.Mode = keyType

	err = initVerifierDetails(conf, logger)(accountPrivateKey, accountAddress, network)
	if err != nil {
		return
	}

	return initFilesWithConfig(config)
}

func initAccountPrivateKeyFile(conf *config.Config, logger log.Logger) func(accountPrivateKey string) (fileName string, err error) {
	return func(accountPrivateKey string) (fileName string, err error) {
		fileName = conf.AccountPrivateKeyFileName
		filePath := filepath.Join(conf.CairoDir, fileName)
		if tmos.FileExists(filePath) {
			logger.Info("Found  account private key", "path", filePath)
			return
		}
		if err = os.WriteFile(filePath, []byte(accountPrivateKey), 0600); err != nil {
			return
		}
		logger.Info("Generated account private key", "path", filePath)
		return
	}
}

func getVerifierAddress(logger log.Logger) func(accountAddress, accountPrivateKeyPath, network string) (verifierAddress string, err error) {
	return func(accountAddress, accountPrivateKeyPath, network string) (verifierAddress string, err error) {
		verifierAddressBigInt, classHashBigInt, err := smartcontracts.DeclareDeploy(accountAddress, accountPrivateKeyPath, network)
		if err != nil {
			return
		}
		verifierAddress = verifierAddressBigInt.Text(16)
		logger.Info("Successfully declared with classhash: ", classHashBigInt.Text(16), "")
		logger.Info("and deployed contract address:", verifierAddress, "")
		return
	}
}

func initVerifierDetails(conf *config.Config, logger log.Logger) func(accountAddress, accountPrivateKey, network string) (err error) {
	return func(accountAddress, accountPrivateKey, network string) (err error) {
		if network == "devnet" && (accountPrivateKey == "0" || accountAddress == "0") {
			accountAddress = "347be35996a21f6bf0623e75dbce52baba918ad5ae8d83b6f416045ab22961a"
			accountPrivateKey = "bdd640fb06671ad11c80317fa3b1799d"
			conf.AccountPrivateKeyFileName = "seed42pkey"
		}
		accountPrivateKeyPath, err := initAccountPrivateKeyFile(conf, logger)(accountPrivateKey)
		if err != nil {
			return
		}

		verifierAddress, err := getVerifierAddress(logger)(accountAddress, accountPrivateKeyPath, network)
		if err != nil {
			return
		}

		vd, err := types.NewVerifierDetails(accountAddress, accountPrivateKeyPath, network, verifierAddress)
		if err != nil {
			return
		}

		err = vd.SaveAs(conf.VerifierDetailsFile())
		return
	}
}

func initFilesWithConfig(config *cfg.Config) error {
	var (
		pv  *privval.FilePV
		err error
	)

	if config.Mode == cfg.ModeValidator {
		// private validator
		privValKeyFile := config.PrivValidator.KeyFile()
		privValStateFile := config.PrivValidator.StateFile()
		if tmos.FileExists(privValKeyFile) {
			pv, err = privval.LoadFilePV(privValKeyFile, privValStateFile)
			if err != nil {
				return err
			}

			logger.Info("Found private validator", "keyFile", privValKeyFile,
				"stateFile", privValStateFile)
		} else {
			pv, err = privval.GenFilePV(privValKeyFile, privValStateFile, keyType)
			if err != nil {
				return err
			}
			pv.Save()
			logger.Info("Generated private validator", "keyFile", privValKeyFile,
				"stateFile", privValStateFile)
		}
	}

	nodeKeyFile := config.NodeKeyFile()
	if tmos.FileExists(nodeKeyFile) {
		logger.Info("Found node key", "path", nodeKeyFile)
	} else {
		if _, err := types.LoadOrGenNodeKey(nodeKeyFile); err != nil {
			return err
		}
		logger.Info("Generated node key", "path", nodeKeyFile)
	}

	// genesis file
	genFile := config.GenesisFile()
	if tmos.FileExists(genFile) {
		logger.Info("Found genesis file", "path", genFile)
	} else {

		genDoc := types.GenesisDoc{
			ChainID:         fmt.Sprintf("test-chain-%v", tmrand.Str(6)),
			GenesisTime:     tmtime.Now(),
			ConsensusParams: types.DefaultConsensusParams(),
		}
		if keyType == "secp256k1" {
			genDoc.ConsensusParams.Validator = types.ValidatorParams{
				PubKeyTypes: []string{types.ABCIPubKeyTypeSecp256k1},
			}
		}

		ctx, cancel := context.WithTimeout(context.TODO(), ctxTimeout)
		defer cancel()

		// if this is a validator we add it to genesis
		if pv != nil {
			pubKey, err := pv.GetPubKey(ctx)
			if err != nil {
				return fmt.Errorf("can't get pubkey: %w", err)
			}
			genDoc.Validators = []types.GenesisValidator{{
				Address: pubKey.Address(),
				PubKey:  pubKey,
				Power:   10,
			}}
		}

		if err := genDoc.SaveAs(genFile); err != nil {
			return err
		}
		logger.Info("Generated genesis file", "path", genFile)
	}

	// write config file
	if err := cfg.WriteConfigFile(config.RootDir, config); err != nil {
		return err
	}
	logger.Info("Generated config", "mode", config.Mode)

	return nil
}
