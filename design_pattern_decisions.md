# Design Pattern Decisions

## Tight Variable Packing

**Tight Variable Packing** was used during the design of the `CapsuleRegistry` storage. An IPFS *multihash* is a 34 bytes value. In order to optimize the storage space, it was split into 3 parts: the hash functions (`uint8`), the hash size (`uint8`) and the IPFS digest (the hash itself) is a `bytes32` value.  

## Emergency Stop and Access Restriction

Although the smart contract `ImageLicensing` is not complex, I have implemented the design patterns *Emergency Stop* and *Access Restriction*. 

**Emergency Stop** is used to stop the contract in case of an emergency. All the `payable` functions will not be executed when the contract is stopped. `view` functions are not affected during this time.

**Access Restriction** is used to allow only the owner of the contract to stop it or resume it. 


## Separation of Concerns

Another design decision was **Separation of Concerns**. In order to make the code simpler and safer, the `CapsulesRegisty` smart contract is responsible only for the registration of *Capsules*. It's basically a storage. All the logic regarding licensing and payments were implemented in the smart contract `ImageLicensing`. `CapsulesRegistry` can be used in many different use cases and `ImageLicensing` can be seen as a client that explores one of the possibilities.

