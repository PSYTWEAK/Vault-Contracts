pragma solidity ^0.8.0;

import "./Vault.sol";

/* 
$$$$$$$$\                   $$\                                   
$$  _____|                  $$ |                                  
$$ |   $$$$$$\   $$$$$$$\ $$$$$$\    $$$$$$\   $$$$$$\  $$\   $$\ 
$$$$$\ \____$$\ $$  _____|\_$$  _|  $$  __$$\ $$  __$$\ $$ |  $$ |
$$  __|$$$$$$$ |$$ /        $$ |    $$ /  $$ |$$ |  \__|$$ |  $$ |
$$ |  $$  __$$ |$$ |        $$ |$$\ $$ |  $$ |$$ |      $$ |  $$ |
$$ |  \$$$$$$$ |\$$$$$$$\   \$$$$  |\$$$$$$  |$$ |      \$$$$$$$ |
\__|   \_______| \_______|   \____/  \______/ \__|       \____$$ |
                                                        $$\   $$ |
    ___               _   ___      _   _                \$$$$$$  |
   /   \___  __ _  __| | / __\   _| |_(_) ___  ___       \______/
  / /\ / _ \/ _` |/ _` |/ / | | | | __| |/ _ \/ __|
 / /_//  __/ (_| | (_| / /__| |_| | |_| |  __/\__ \
/___,' \___|\__,_|\__,_\____/\__,_|\__|_|\___||___/     

*/

contract VaultFactory {
    mapping(address => Vault) vaults;

    /**
     * Creates a new Vault and gives ownership to message sender
     * Note: only message sender can deposit, unlock and withdraw
     * from this vault.
     * DO NOT SET backupAddressForEmergency TO AN ADDRESS WITH THE
     * SAME PRIVATE KEY AS MESSAGE SENDER
     * @param backupAddressForEmergency ownership of vault will be transfered to this address in case of PK compromise
     */
    function createVault(address backupAddressForEmergency) public {
        Vault vault = new Vault(backupAddressForEmergency);
        vault.transferOwnership(msg.sender);
        storeVault(vault);
    }

    function storeVault(Vault vault) internal {
        vaults[msg.sender] = vault;
    }

    /**
     * Gets the contract address for an existing vault
     * @param account the account which created the vault
     */
    function getVault(address account) public view returns (address) {
        return address(vaults[account]);
    }
}
