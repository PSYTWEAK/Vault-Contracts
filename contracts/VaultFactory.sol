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
