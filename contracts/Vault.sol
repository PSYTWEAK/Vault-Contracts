pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import "./VaultInternal.sol";

/* 
$$\    $$\                    $$\   $$\     
$$ |   $$ |                   $$ |  $$ |    
$$ |   $$ |$$$$$$\  $$\   $$\ $$ |$$$$$$\   
\$$\  $$  |\____$$\ $$ |  $$ |$$ |\_$$  _|  
 \$$\$$  / $$$$$$$ |$$ |  $$ |$$ |  $$ |    
  \$$$  / $$  __$$ |$$ |  $$ |$$ |  $$ |$$\ 
   \$  /  \$$$$$$$ |\$$$$$$  |$$ |  \$$$$  |
    \_/    \_______| \______/ \__|   \____/ 
    ___               _   ___      _   _           
   /   \___  __ _  __| | / __\   _| |_(_) ___  ___ 
  / /\ / _ \/ _` |/ _` |/ / | | | | __| |/ _ \/ __|
 / /_//  __/ (_| | (_| / /__| |_| | |_| |  __/\__ \
/___,' \___|\__,_|\__,_\____/\__,_|\__|_|\___||___/
*/

contract Vault is VaultInternal {
    /*  
    ================================================================
                            Contructor 
    ================================================================ 
    */

    constructor(address _backupAddressForEmergency) {
        backupAddressForEmergency = _backupAddressForEmergency;
    }

    /*  
    ================================================================
                        Public Functions 
    ================================================================ 
    */

    function deposit(
        address[] memory unlockedERC721s,
        uint256[][] memory tokenIds
    ) public onlyOwner {
        for (uint256 i; i < unlockedERC721s.length; i++) {
            depositMutipleOfCollection(unlockedERC721s[i], tokenIds[i]);
        }
    }

    function withdraw(
        address[] memory unlockedERC721s,
        uint256[][] memory tokenIds
    ) public onlyOwner {
        for (uint256 i; i < unlockedERC721s.length; i++) {
            withdrawMultipleOfCollection(unlockedERC721s[i], tokenIds[i]);
        }
    }

    function unlock(address unlockedERC721, uint256 tokenId) public onlyOwner {
        whenSingleERC721Unlocked[currentUnlockedTimestampVersion][
            unlockedERC721
        ][tokenId] = block.timestamp + unlockDelay;
    }

    function unlockAll() public onlyOwner {
        whenAllERC721Unlocked = block.timestamp + unlockDelay;
    }

    function lockAll() public onlyOwner {
        whenAllERC721Unlocked = 0;
        resetAllSingleERC721Timestamps();
    }

    function acceptEmergencyInviteForBackupAddressToTakeControl(
        bytes memory signature
    ) external onlyBackupAddress checkValidSignature(signature) {
        _transferOwnership(backupAddressForEmergency);
    }

    function transferOwnership(address owner) public override onlyOwner {
        require(!hasOwner, "Vault: Owner already set on creation");
        _transferOwnership(owner);
        hasOwner = true;
    }

    /*  
    ================================================================
                        Public View Functions 
    ================================================================ 
    */

    function getWhenSingleERC721Unlocked(
        address unlockedERC721,
        uint256 tokenId
    ) public view returns (uint256) {
        return
            whenSingleERC721Unlocked[currentUnlockedTimestampVersion][
                unlockedERC721
            ][tokenId];
    }

    function getWhenAllERC721Unlocked() public view returns (uint256) {
        return whenAllERC721Unlocked;
    }

    function onERC721Received(
        address,
        address,
        uint256,
        bytes memory
    ) public returns (bytes4) {
        return this.onERC721Received.selector;
    }
}
