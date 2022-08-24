%lang starknet
from starkware.cairo.common.math import assert_nn
from starkware.cairo.common.cairo_builtins import HashBuiltin, SignatureBuiltin
from starkware.cairo.common.math_cmp import is_le, is_not_zero
from starkware.cairo.common.uint256 import Uint256, uint256_mul, uint256_unsigned_div_rem, uint256_lt
from starkware.cairo.common.signature import verify_ecdsa_signature
from starkware.cairo.common.hash import hash2


struct TENDERMINTLIGHT_PROTO_GLOBAL_ENUMSBlockIDFlag:

    # In the original Solidity code, an enum is used
    # to represent the different types of blocks.
    # However, in Cairo there are no enums, so we use
    # the following constants
    # will take values of 0,1,2,3 based on https://github.com/ChorusOne/tendermint-sol/blob/main/contracts/proto/TendermintLight.sol#L8870
    member BlockIDFlag: felt 

end

const BLOCK_ID_FLAG_UNKNOWN = 0
const BLOCK_ID_FLAG_ABSENT = 1
const BLOCK_ID_FLAG_COMMIT = 2
const BLOCK_ID_FLAG_NIL = 3

const MAX_TOTAL_VOTING_POWER = 4611686018427387904 # == 1 << (63 - 1)

# TimestampData is done
struct TimestampData:
    member Seconds: felt # TODO should be int64
    member nanos: felt # TODO should be int32
end

struct SignatureData:
    member signature_r: felt
    member signature_s: felt

end

# CommitSigData is done
struct CommitSigData:
    member block_id_flag: TENDERMINTLIGHT_PROTO_GLOBAL_ENUMSBlockIDFlag
    member validators_address: felt # TODO should be bytes
    member timestamp: TimestampData
    member signature: SignatureData # TODO should be bytes

end

# PartSetHeader is done
struct PartSetHeaderData:
    member total: felt # TODO should be uint64
    member hash: felt # TODO should be bytes

end

# BlockIDData is done
struct BlockIDData:
    member hash: felt # TODO needs to be bytes
    member part_set_header: PartSetHeaderData

end

# DurationData is done
struct DurationData:
    member Seconds: felt # TODO should be int64
    member nanos: felt # TODO should be int32
end

struct CommitSigDataArray:
    member array: CommitSigData*
    member len: felt
end

# TODO: implement signatures as an array of unknown length
struct CommitData:
    member height: felt #TODO replace with int64
    member round: felt #TODO replace with int32
    member block_id: BlockIDData # TODO implement BlockIDData
    # the following line should be a list of CommitSigData
    member signatures: CommitSigDataArray # TODO implement CommitSigData
    # the above line is invalid because is a pointer
end

# ConsensusData is done
struct ConsensusData:
    member block: felt # TODO replace with uint64
    member app: felt # TODO replace with uint64

end

struct LightHeaderData:
    member version: ConsensusData # TODO maybe this needs to be a pointer
    member chain_id: felt # TODO replace with hash of string
    member height: felt # TODO replace with int64
    member time: TimestampData
    member last_block_id: BlockIDData
    member last_commit_hash: felt # TODO replace with bytes
    member data_hash: felt # TODO replace with bytes
    member validators_hash: felt # TODO replace with bytes
    member next_validators_hash: felt # TODO replace with bytes
    member consensus_hash: felt # TODO replace with bytes
    member app_hash: felt # TODO replace with bytes
    member last_results_hash: felt # TODO replace with bytes
    member proposer_address: felt # TODO replace with bytes
    
end

# Done
struct SignedHeaderData:
    member header: LightHeaderData
    member commit: CommitData
end

# Array types
struct ValidatorDataArray:
    member array: ValidatorData*
    member len: felt
end

struct PublicKeyData:
    member ed25519: felt # TODO bytes
    member secp256k1: felt # TODO bytes
    member sr25519: felt # TODO bytes
    member ecdsa: felt 
end

struct ValidatorData:
    member Address: felt # TODO bytes
    member pub_key: PublicKeyData
    member voting_power: felt # TODO int64
    member proposer_priority: felt # TODO int64
end

struct ValidatorSetData:
    member validators: ValidatorDataArray
    member proposer: ValidatorData
    member total_voting_power: felt # TODO int64
end

struct FractionData:
    member numerator: felt
    member denominator: felt
end


# function for checking whether which time stamp is larger
# returns 1 if first is larger, 0 in both other cases
func time_greater_than{range_check_ptr}(
    t1: TimestampData,
    t2: TimestampData 
    )->(res:felt):
    alloc_locals

    let (is_le_val: felt) = is_le(t2.Seconds, t1.Seconds)

    if is_le_val == 1:
        # check if t1 is equal to t2
        # let (local t1S: felt) = t1.Seconds
        # let (local t2S: felt) = t2.Seconds
        tempvar t1S: felt = t1.Seconds
        tempvar t2S: felt = t2.Seconds 
        tempvar time_diff: felt = t1S - t2S
        let (not_equal: felt) = is_not_zero(time_diff) 
        
        if not_equal == 1:
            return(1)
        else:
        # they are equal, check nanos
            let (is_le_val_nanos: felt) = is_le(t2.nanos, t1.nanos)
            
            if is_le_val_nanos == 1:
                tempvar t1n: felt = t1.nanos
                tempvar t2n: felt = t2.nanos
                tempvar time_diff_nanos: felt = t1n - t2n
                let (not_equal_nanos: felt) = is_not_zero(time_diff_nanos)
            

                if not_equal_nanos == 1:
                    return(1)
                else:
                    return(0)
                end          

            else:
                return(0)
            end
        end 
    else:
        return(0)  
    end

end


# check if the header is valid
func isExpired{range_check_ptr}(
    header: SignedHeaderData,
    trustingPeriod: DurationData,
    currentTime: DurationData
    )->(res:felt):

    # add the trusting period to the current time
    # create new DurationData struct

    let expirationTime: TimestampData = TimestampData(
        Seconds= header.header.time.Seconds + trustingPeriod.Seconds,
        nanos= header.header.time.nanos + trustingPeriod.nanos
    )

    let currentTime_TimestampData = TimestampData(
        Seconds= currentTime.Seconds,
        nanos= currentTime.nanos
    )
    return time_greater_than(currentTime_TimestampData, expirationTime)

end

# returns 1 if a>b, else 0
func greater_than{range_check_ptr}(
    a: felt,
    b: felt
    )->(res:felt):
    let (is_le_val: felt) = is_le(b, a)
    if is_le_val == 1:
        # check if they are equal
        tempvar ab_diff: felt = a - b
        let (not_equal: felt) = is_not_zero(ab_diff) 
        if not_equal == 1:
            return(1)
        else:
            return(0)
        end 
    else:
        return(0)
    end

end

# TODO change dummy hash function to a real one
func ourHashFunction{range_check_ptr}(untrustedHeader: SignedHeaderData)->(res:felt):
    return(11)
end

func verifyNewHeaderAndVals{range_check_ptr}(
    untrustedHeader: SignedHeaderData,
    # untrustedVals: ValidatorSetData, # TODO implement ValidatorSetData
    trustedHeader: SignedHeaderData,
    currentTime: DurationData,
    maxClockDrift: DurationData
    )->(res:felt):

    # set of simple checks to see if the header is valid

    # check if the chain id is the same

    tempvar untrusted_chain_id: felt = untrustedHeader.header.chain_id
    tempvar trusted_chain_id: felt = trustedHeader.header.chain_id
    assert untrusted_chain_id = trusted_chain_id

    # check if commit hights are the same
    tempvar untrusted_commit_height: felt = untrustedHeader.commit.height
    tempvar untrusted_header_height: felt = untrustedHeader.header.height
    assert untrusted_commit_height = untrusted_header_height

    # check if the header hash is the one we expect
    # TODO based on https://github.com/ChorusOne/tendermint-sol/blob/main/contracts/utils/Tendermint.sol#L137
    # let (untrusted_header_block_hash: felt) = ourHashFunction(untrustedHeader)
    # tempvar untrusted_header_commit_block_id_hash: felt = untrustedHeader.commit.block_id.hash
    # assert untrusted_header_block_hash = untrusted_header_commit_block_id_hash 

    # check if the untrusted header height to be greater
    # than the trusted header height
    tempvar untrusted_height: felt = untrustedHeader.header.height
    tempvar trusted_height: felt = trustedHeader.header.height

    let (untrusted_greater: felt) = greater_than(untrusted_height, trusted_height)
    assert untrusted_greater = 1

    # check if the untrusted header time is greater than the trusted header time
    tempvar untrusted_time: TimestampData = untrustedHeader.header.time
    tempvar trusted_time: TimestampData = trustedHeader.header.time
    let (untrusted_time_greater: felt) = time_greater_than(untrusted_time, trusted_time)
    assert untrusted_time_greater = 1

    # check if the untrusted header time is greater than the current time
    tempvar untrusted_time: TimestampData= untrustedHeader.header.time

    let driftTime: TimestampData = TimestampData(
        Seconds= currentTime.Seconds + maxClockDrift.Seconds,
        nanos= currentTime.nanos + maxClockDrift.nanos
    )
    let (untrusted_time_greater_current: felt) = time_greater_than(driftTime, untrusted_time )
    assert untrusted_time_greater_current = 1

    # check if the header validators hash is the onne supplied
    # TODO based on https://github.com/ChorusOne/tendermint-sol/blob/main/contracts/utils/Tendermint.sol#L161


    return(1)
end

# the solidity code here is not very professional
# I remove the total_voting_power_parameter
# because we work with immutable variables
func get_total_voting_power(
    validators_len: felt,
    validators: ValidatorData*
) -> (res: felt):
    if validators_len == 0:
        return (0)
    end
    %{print(ids.validators_len)%}
    let (sum: felt) = get_total_voting_power(validators_len - 1, validators + 6)
    # TODO assert sum < MAX_TOTAL_VOTING_POWER
    let first_vals: ValidatorData = [validators]
    let voting_power: felt = first_vals.voting_power
    %{print('ids.voting_power')%}
    %{print(ids.voting_power)%}
    return (voting_power + sum)
end

# TODO complete the verify function
func ed25519_verify(
    message: felt,
    public_key: felt,
    signature: felt
) -> (res: felt):
    return (1)
end

# TODO complete the verify function
func secp256k1_verify(
    message: felt,
    public_key: felt,
    signature: felt
) -> (res: felt):
    return (1)
end


func canonicalPartSetHeaderHasher{
    pedersen_ptr : HashBuiltin*}(
    part_set_header: PartSetHeaderData)
    ->(res_hash:felt):

    alloc_locals
    local total: felt = part_set_header.total
    local hash: felt = part_set_header.hash
    let (res_hash) = hash2{hash_ptr=pedersen_ptr}(total, hash)

    return(res_hash)

end


func blockIDHasher{pedersen_ptr : HashBuiltin*}(block_id: BlockIDData)->(res_hash: felt):
    alloc_locals

    local bidd_hash: felt = block_id.hash
    local part_set_header: PartSetHeaderData = block_id.part_set_header

    let (psh_hash) = canonicalPartSetHeaderHasher(part_set_header)
    let (res_hash) = hash2{hash_ptr=pedersen_ptr}(bidd_hash, psh_hash)

    return(res_hash)
end

func hashCanonicalVoteNoTime{pedersen_ptr : HashBuiltin*}(
    commit: CommitData, chain_id: felt)->(res:felt):
    alloc_locals
    
    local type: felt = 1 # stand in value for Type https://github.com/kelemeno/tendermint-stark/blob/main/types/canonical.go#L95
    local height: felt = commit.height
    local round: felt = commit.round
    local block_id: BlockIDData= commit.block_id

    let (res_bidd) = blockIDHasher(block_id = block_id) 
    
    let (res_1) = hash2{hash_ptr=pedersen_ptr}(type, height)
    let (res_2) = hash2{hash_ptr=pedersen_ptr}(res_1, round)
    let (res_3) = hash2{hash_ptr=pedersen_ptr}(res_2, res_bidd)
    let (res_4) = hash2{hash_ptr=pedersen_ptr}(res_3, chain_id)

    return(res_4)

end

func voteSignBytes{}(
    commit: CommitData,
    chain_id: felt,
    idx: felt
    )->():

    # join chainID and vote
    # hash joint
    # get a timestamp
    # append hash to timestamp


    return()

end


# TODO complete
func verifySig{ecdsa_ptr : SignatureBuiltin*}(
    val: ValidatorData,
    message: felt, # bytes
    signature: SignatureData 
) -> (res: felt):
    alloc_locals

    # call verify_ecdsa_signature
    # here the two parts of the signature will be passed on from Tendermint
    local pub_key: felt = val.pub_key.ecdsa
    # local sig_r: felt = val.pub_key.ecdsa_r
    
    local sig_r = signature.signature_r
    local sig_s = signature.signature_s
    

    # behaves like an assert
    verify_ecdsa_signature(message=message, public_key=pub_key,signature_r = sig_r , signature_s=sig_s )
    return(1)
end

func get_tallied_voting_power(
    signatures_len: felt,
    signatures: CommitSigData*,
    validators_len: felt,
    validators: ValidatorData*
)->(res: felt):
    alloc_locals

    # need to set the value to 0 here or to -1?
    if signatures_len == 0:
        return (0)
    end

    local signature: CommitSigData = [signatures]
    local val: ValidatorData = [validators]

    tempvar BlockIDFlag = signature.block_id_flag.BlockIDFlag
    tempvar valsize = ValidatorData.SIZE

    # if signature.block_id_flag.BlockIDFlag != BLOCK_ID_FLAG_COMMIT:
    if BlockIDFlag != BLOCK_ID_FLAG_COMMIT:
        let (rest_of_voting_power: felt) = get_tallied_voting_power(
            signatures_len - 1,
            signatures + 6,
            validators_len -1,
            validators +6 
        )
        return (rest_of_voting_power)
    end
    
    # TODO Delim encoding
    # voteSignBytes
    # TODO verifySig filter
    
    
    let (rest_of_voting_power: felt) = get_tallied_voting_power(
        signatures_len - 1,
        signatures + 6,
        validators_len -1 ,
        validators +6
    )
    return (val.voting_power + rest_of_voting_power)
end

# return 0 (false) or 1 (true)
func verifyCommitLight{range_check_ptr}(
    vals: ValidatorSetData,
    chainID: felt, # please check this type guys
    blockID: BlockIDData,
    height: felt, # TODO int64
    commit: CommitData,
    # commit_signatures_length: felt,
    # commit_signatures_array: CommitSigData*
)->(res: felt):
    alloc_locals
    # tempvar vals_validators_length_temp: felt = vals.validators.len
    local vals_validators_length: felt = vals.validators.len
    # let (local vals_validators_length: felt) = vals_validators_length_temp
    tempvar commit_signatures_length: felt = commit.signatures.len
    assert vals_validators_length = commit_signatures_length
    
    tempvar commit_height = commit.height
    assert height = commit_height

    # This is the only way to compare two structs (BlockID)
    # following checks are equivalent to: require(commit.block_id.isEqual(blockID), "invalid commit -- wrong block ID");
    # need to check all parts of the struct

    tempvar blockid_hash = blockID.hash
    tempvar blockid_part_set_header_total = blockID.part_set_header.total
    tempvar blockid_part_set_header_hash = blockID.part_set_header.hash

    tempvar commit_blockid_hash = commit.block_id.hash
    tempvar commit_blockid_part_set_header_total = commit.block_id.part_set_header.total
    tempvar commit_blockid_part_set_header_hash = commit.block_id.part_set_header.hash

    assert blockid_hash = commit_blockid_hash
    assert blockid_part_set_header_total = commit_blockid_part_set_header_total
    assert blockid_part_set_header_hash = commit_blockid_part_set_header_hash

    # get the commit_signatures pointer
    # get the validatordata pointer

    tempvar vals_validators_array: ValidatorData*= vals.validators.array
    tempvar commit_signatures_array: CommitSigData* = commit.signatures.array

    # call get_tallied_voting_power to get the counts
    let (tallied_voting_power: felt) = get_tallied_voting_power(signatures_len=commit_signatures_length, signatures=commit_signatures_array, validators_len=vals_validators_length, validators=vals_validators_array)
    
    let (total_voting_power: felt) = get_total_voting_power(validators_len=vals_validators_length, validators=vals_validators_array)

    # let tallied_voting_power_uint= Uint256(low= 1, high=0 )
    let tallied_voting_power_uint = Uint256(low= tallied_voting_power, high=0 )
    let total_voting_power_uint= Uint256(low= total_voting_power, high=0 )

    let numerator  = Uint256(low= 2, high=0)
    let denominator  = Uint256(low= 3, high=0)

   # find 2/3 of the total voting power with multiplying by uint256_mul and dividing uint256_unsigned_div_rem

    let (mul_low , mul_high ) = uint256_mul(a= total_voting_power_uint,b= numerator)

    let (div_quotient , div_remainder ) =  uint256_unsigned_div_rem(a= mul_low, div= denominator )

    # compare the value resulting from the dvsion to the tallied_voting_power_uint

    let (more_tallied_votes:felt) = uint256_lt(div_quotient, tallied_voting_power_uint)

    assert more_tallied_votes=1


    return(0)
end

# @external
func verifyAdjacent{range_check_ptr} (
    trustedHeader: SignedHeaderData,
    # trustedHeader_commit_signatures_len: felt,
    # trustedHeader_commit_signatures: CommitSigData*,
    untrustedHeader: SignedHeaderData,
    # untrustedHeader_commit_signatures_len: felt,
    # untrustedHeader_commit_signatures: CommitSigData*,
    untrustedVals: ValidatorSetData,
    trustingPeriod: DurationData,
    currentTime: DurationData,
    maxClockDrift: DurationData

    # the following res returns a 0 or 1 boolean
) -> (res: felt) :
    
    # check if the headers come from adjacent blocks
    assert untrustedHeader.header.height = trustedHeader.header.height + 1

    # check that header is expired

    let (expired:felt) =  isExpired(
        header= untrustedHeader,
        trustingPeriod= trustingPeriod,
        currentTime= currentTime
    ) 

    # make sure the header is not expired
    assert expired = 0

    verifyNewHeaderAndVals(untrustedHeader, trustedHeader,
    currentTime, maxClockDrift)

    verifyCommitLight(
        vals=untrustedVals,
        chainID=trustedHeader.header.chain_id, # please check this type guys
        blockID=untrustedHeader.commit.block_id,
        height=untrustedHeader.header.height, # TODO int64
        commit=untrustedHeader.commit
    )

    return (1)
end 

func verifyNonAdjacent{range_check_ptr} (
    trustedHeader: SignedHeaderData,
    trustedVals: ValidatorSetData,
    untrustedHeader: SignedHeaderData,
    untrustedVals: ValidatorSetData,
    trustingPeriod: DurationData,
    currentTime: DurationData,
    maxClockDrift: DurationData,
    trustLevel: FractionData
) -> (res: felt):
    tempvar untrusted_header_height = untrustedHeader.header.height
    tempvar trusted_header_height = trustedHeader.header.height
    if untrusted_header_height == trusted_header_height + 1:
        assert 1 = 2
    end

    ###############
    # TODO Hash check
    #    require(
    #        trustedVals.hash() == trustedHeader.header.next_validators_hash.toBytes32(),
    #        "LC: headers trusted validators does not hash to latest trusted validators"
    #    );
    ###############


    let (expired:felt) =  isExpired(
        header= untrustedHeader,
        trustingPeriod= trustingPeriod,
        currentTime= currentTime
    ) 

    # make sure the header is not expired
    assert expired = 0

    verifyNewHeaderAndVals(untrustedHeader, trustedHeader,
    currentTime, maxClockDrift)

    verifyCommitLight(
        vals=untrustedVals,
        chainID=trustedHeader.header.chain_id, # please check this type guys
        blockID=untrustedHeader.commit.block_id,
        height=untrustedHeader.header.height, # TODO int64
        commit=untrustedHeader.commit
    )
    return (0)
end








