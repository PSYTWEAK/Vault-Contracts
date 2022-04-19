pragma solidity ^0.8.0;

import "./Vault.sol";

contract VaultFactory {
    mapping(address => Vault) vaults;

    function createVault(address backupAddressForEmergency) public {
        Vault vault = new Vault(backupAddressForEmergency);
        vault.transferOwnership(msg.sender);
        storeVault(vault);
    }

    function storeVault(Vault vault) internal {
        vaults[msg.sender] = vault;
    }

    function getVault(address account) public view returns (address) {
        return address(vaults[account]);
    }
}
