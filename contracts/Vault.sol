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

    function deposit(uint256 tokenId, address ERC721Addr)
        external
        onlyOwner
        checkLockedERC721Exists(ERC721Addr)
    {
        transferERC721(tokenId, ERC721Addr);
        mintLockedERC721(tokenId);
    }

    function unlock(uint256 tokenId) external onlyOwner {
        timeUntilSingleNFTUnlocked[tokenId] = block.timestamp + unlockDelay;
    }

    function unlockAll() external onlyOwner {
        timeUntilAllUnlocked = block.timestamp + unlockDelay;
    }

    function withdraw(uint256 tokenId, address ERC721Addr)
        public
        onlyOwner
        checkIsUnlocked(tokenId, ERC721Addr)
    {
        burnLockedERC721(tokenId);
        ERC721Addr.safeTransferFrom(address(this), msg.sender, tokenId);
    }

    function withdrawMultiple(uint256[] memory tokenId) external onlyOwner {
        for (uint256 i; i < tokenId.length; i++) {
            withdraw(tokenId[i]);
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
