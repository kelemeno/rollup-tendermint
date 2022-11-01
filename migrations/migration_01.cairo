%lang starknet

@external
func up() {
    %{
        #contract_address = deploy_contract("./build/main.json", config={"wait_for_acceptance": True}).contract_address
          #335674479734934146889037038263903380498452542860978104900782795296756624142,
          # "0xbdfc2a72d8828a45531126520bf5f981434d95922dc2867857874fa9966b0e",
        invoke(
            1829417211792761510102971298743435514211364236529393179603110538781091184815,
            "externalVerifyAdjacent",
            {
                "chain_id_array": [
                    116,
                    7310314358442582377,
                    7939082473277174873
                ],
                "trusted_commit_sig_array": [
                    {
                        "block_id_flag": {
                            "BlockIDFlag": 2
                        },
                        "validator_address": 335674479734934146889037038263903380498452542860978104900782795296756624142,

                        "timestamp": {
                            "nanos": 1665753877127453388
                        },
                        "signature": {
                            "signature_r": 1834131662309943167060654729634590738983734585222746799362362058903754262332,
                            "signature_s": 1745065597501682152537867859965459308365142243262023073853228716084356784546
                        }
                    }
                ],
                "untrusted_commit_sig_array": [
                    {
                        "block_id_flag": {
                            "BlockIDFlag": 2
                        },
                        "validators_address": 335674479734934146889037038263903380498452542860978104900782795296756624142,
                        "timestamp": {
                            "nanos": 1665753889554053779
                        },
                        "signature": {
                            "signature_r": 3605504498823257379762570133327870210455706278164450482388963404778814325454,
                            "signature_s": 3133371732092557530256163168714261110099475276750495027673839161202089731597
                        }
                    }
                ],
                "validator_array": [
                    {
                        "Address": 335674479734934146889037038263903380498452542860978104900782795296756624142,
                        "pub_key": {
                            "ecdsa": 3334500756028199475433036722527134417926233723147766471089429384364098171865
                        },
                        "voting_power": 10,
                        "proposer_priority": 0
                    }
                ],
                "trusted": {
                    "header": {
                        "consensus_data": {
                            "block": 11,
                            "app": 1
                        },
                        "height": 2,
                        "time": {
                            "nanos": 1665753871520445159
                        },
                        "last_block_id": {
                            "hash": 2606409042684652237028761825612341298588373841266340846590208831812555967679,
                            "part_set_header": {
                                "total": 1,
                                "hash": 3000838125350084652609540693524514269948277526780094801048010237669338709953
                            }
                        },
                        "last_commit_hash": 1931616577660260768497627594988710925560949687119466413940080031015097594698,
                        "data_hash": 2089986280348253421170679821480865132823066470938446095505822317253594081284,
                        "validators_hash": 2831012649517925635638083284349758092553206116379646415063645608642406529898,
                        "next_validators_hash": 2831012649517925635638083284349758092553206116379646415063645608642406529898,
                        "consensus_hash": 2132461975834504200398180281070409533541683498016798668455504133351250391630,
                        "app_hash": 0,
                        "last_results_hash": 2089986280348253421170679821480865132823066470938446095505822317253594081284,
                        "evidence_hash": 2089986280348253421170679821480865132823066470938446095505822317253594081284,
                        "proposer_address": 335674479734934146889037038263903380498452542860978104900782795296756624142
                    },
                    "commit": {
                        "height": 2,
                        "round": 0,
                        "block_id": {
                            "hash": 2059766791315474971233242291515003944317013849850428055013818287621749261948,
                            "part_set_header": {
                                "total": 1,
                                "hash": 1308036548029847327855861229891709942163426033933946107172305588954015556391
                            }
                        }
                    }
                },
                "untrusted": {
                    "header": {
                        "consensus_data": {
                            "block": 11,
                            "app": 1
                        },
                        "height": 3,
                        "time": {
                            "nanos": 1665753884507525850
                        },
                        "last_block_id": {
                            "hash": 2059766791315474971233242291515003944317013849850428055013818287621749261948,
                            "part_set_header": {
                                "total": 1,
                                "hash": 1308036548029847327855861229891709942163426033933946107172305588954015556391
                            }
                        },
                        "last_commit_hash": 465267704775716075860689654059997816995530962997902813659991924419196233437,
                        "data_hash": 2089986280348253421170679821480865132823066470938446095505822317253594081284,
                        "validators_hash": 2831012649517925635638083284349758092553206116379646415063645608642406529898,
                        "next_validators_hash": 2831012649517925635638083284349758092553206116379646415063645608642406529898,
                        "consensus_hash": 2132461975834504200398180281070409533541683498016798668455504133351250391630,
                        "app_hash": 0,
                        "last_results_hash": 2089986280348253421170679821480865132823066470938446095505822317253594081284,
                        "evidence_hash": 2089986280348253421170679821480865132823066470938446095505822317253594081284,
                        "proposer_address": 335674479734934146889037038263903380498452542860978104900782795296756624142
                    },
                    "commit": {
                        "height": 3,
                        "round": 0,
                        "block_id": {
                            "hash": 490484232464039218793463646794795012959740951355156173400258415888395419419,
                            "part_set_header": {
                                "total": 1,
                                "hash": 1680373902317584836581677072736116216148431538470704822243182371928708897588
                            }
                        }
                    }
                },
                "validator_set_args": {
                    "proposer": {
                        "Address": 335674479734934146889037038263903380498452542860978104900782795296756624142,
                        "pub_key": {
                            "ecdsa": 3334500756028199475433036722527134417926233723147766471089429384364098171865
                        },
                        "voting_power": 10,
                        "proposer_priority": 0
                    },
                    "total_voting_power": 10
                },
                "verification_args": {
                    "current_time": {
                        "nanos": 1665753884507526850
                    },
                    "max_clock_drift":{
                        "nanos": 10
                    },
                    "trusting_period":{
                        "nanos": 99999999999999999999
                    }
                }
            },
            config={
                "max_fee": "auto",
                "wait_for_acceptance": True
            }
        )
    %}

    return ();
}
