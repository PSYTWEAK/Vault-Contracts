pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import "./VaultInternal.sol";

/* 
Yb    dP    db    88   88 88     888888 
 Yb  dP    dPYb   88   88 88       88   
  YbdP    dP__Yb  Y8   8P 88  .o   88   
   YP    dP""""Yb `YbodP' 88ood8   88  
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
                    External Functions 
    ================================================================ 
    */

    function deposit(address unlockedERC721, uint256 tokenId)
        external
        onlyOwner
        checkLockedERC721Exists(unlockedERC721)
    {
        transferERC721(unlockedERC721, tokenId);
        mintLockedERC721(unlockedERC721, tokenId);
    }

    function unlock(address unlockedERC721, uint256 tokenId)
        external
        onlyOwner
    {
        timestampForSingleNFTUnlocked[unlockedERC721][tokenId] =
            block.timestamp +
            unlockDelay;
    }

    function unlockAll() external onlyOwner {
        timestampForAllNFTsUnlocked = block.timestamp + unlockDelay;
    }

    function withdraw(address unlockedERC721, uint256 tokenId)
        public
        onlyOwner
        checkIsUnlocked(unlockedERC721, tokenId)
    {
        burnLockedERC721(unlockedERC721, tokenId);
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
    ) external onlyOwner {
        for (uint256 i; i < unlockedERC721s.length; i++) {
            withdrawMultipleOfCollection(unlockedERC721s[i], tokenIds[i]);
        }
    }

    /*  
    ================================================================
                Emergency Backup address Functions 
    ================================================================ 
    */

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

    function onERC721Received(
        address,
        address,
        uint256,
        bytes memory
    ) public returns (bytes4) {
        return this.onERC721Received.selector;
    }
}
