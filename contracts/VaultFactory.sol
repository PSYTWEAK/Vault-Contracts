pragma solidity ^0.8.0;

import "./Vault.sol";

contract VaultFactory {
    event VaultCreated(address vaultAddress, address NFT);

    mapping(address => mapping(address => Vault)) vaults;

    function createVault(
        address NFTContractAddress,
        address backupAddressForEmergency
    ) public {
        Vault vault = new Vault(NFTContractAddress, backupAddressForEmergency);
        vault.transferOwnership(msg.sender);
        vaults[msg.sender][NFTContractAddress] = vault;
        emit VaultCreated(address(vault), NFTContractAddress);
    }

    function getVault(address account, address NFTContractAddress)
        public
        view
        returns (address)
    {
        return address(vaults[account][NFTContractAddress]);
    }
}
