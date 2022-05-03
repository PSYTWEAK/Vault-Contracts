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

    //========================= Deposits ==============================

    function deposit(address unlockedERC721, uint256 tokenId)
        public
        onlyOwner
        checkLockedERC721Exists(unlockedERC721)
    {
        transferERC721(unlockedERC721, tokenId);
        mintLockedToken(unlockedERC721, tokenId);
    }

    function depositMutipleOfCollection(
        address unlockedERC721,
        uint256[] memory tokenIds
    ) public onlyOwner {
        for (uint256 i; i < tokenIds.length; i++) {
            deposit(unlockedERC721, tokenIds[i]);
        }
    }

    function depositMutiple(
        address[] memory unlockedERC721s,
        uint256[][] memory tokenIds
    ) public onlyOwner {
        for (uint256 i; i < unlockedERC721s.length; i++) {
            depositMutipleOfCollection(unlockedERC721s[i], tokenIds[i]);
        }
    }

    //========================= Unlocks ==============================

    function unlock(address unlockedERC721, uint256 tokenId) public onlyOwner {
        timestampForSingleNFTUnlocked[unlockedERC721][tokenId] =
            block.timestamp +
            unlockDelay;
    }

    function unlockAll() public onlyOwner {
        timestampForAllNFTsUnlocked = block.timestamp + unlockDelay;
    }

    //========================= Unlocks ==============================

    function lock(address unlockedERC721, uint256 tokenId) public onlyOwner {
        timestampForSingleNFTUnlocked[unlockedERC721][tokenId] = 0;
    }

    function lockAll() public onlyOwner {
        timestampForAllNFTsUnlocked = 0;
    }

    //========================= Withdraws ==============================

    function withdraw(address unlockedERC721, uint256 tokenId)
        public
        onlyOwner
        checkIsUnlocked(unlockedERC721, tokenId)
    {
        burnLockedToken(unlockedERC721, tokenId);
        IUnlockedERC721(unlockedERC721).safeTransferFrom(
            address(this),
            msg.sender,
            tokenId
        );
    }

    function withdrawMultipleOfCollection(
        address unlockedERC721,
        uint256[] memory tokenIds
    ) public onlyOwner {
        for (uint256 i; i < tokenIds.length; i++) {
            withdraw(unlockedERC721, tokenIds[i]);
        }
    }

    function withdrawMultiple(
        address[] memory unlockedERC721s,
        uint256[][] memory tokenIds
    ) public onlyOwner {
        for (uint256 i; i < unlockedERC721s.length; i++) {
            withdrawMultipleOfCollection(unlockedERC721s[i], tokenIds[i]);
        }
    }

    //====================== Emergency ==============================

    function acceptEmergencyInviteForBackupAddressToTakeControl(
        bytes memory signature
    ) external onlyBackupAddress checkValidSignature(signature) {
        _transferOwnership(backupAddressForEmergency);
    }

    //====================== initializing ==============================

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

    function getTimestampForSingleNFTUnlocked(
        address unlockedERC721,
        uint256 tokenId
    ) public view returns (uint256) {
        return timestampForSingleNFTUnlocked[unlockedERC721][tokenId];
    }

    function getTimestampForAllNFTsUnlocked() public view returns (uint256) {
        return timestampForAllNFTsUnlocked;
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
