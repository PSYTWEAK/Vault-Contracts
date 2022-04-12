pragma solidity ^0.8.0;

import "./Vault.sol";

contract VaultFactory {
    mapping(address => mapping(uint256 => Vault)) vaults;
    mapping(address => uint256) vaultCount;

    function createVault(address backupAddressForEmergency) public {
        Vault vault = new Vault(backupAddressForEmergency);
        vault.transferOwnership(msg.sender);
        storeVault(vault);
    }

    function storeVault(Vault vault) internal {
        vaultCount[msg.sender]++;
        vaults[msg.sender][vaultCount[msg.sender]] = vault;
    }

    function getVault(address account, address NFTContractAddress)
        public
        view
        returns (address)
    {
        return address(vaults[account][NFTContractAddress]);
    }
}
