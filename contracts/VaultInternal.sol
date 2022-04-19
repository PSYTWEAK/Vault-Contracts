pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "./Library/VerifySignature.sol";
import "./LockedERC721.sol";
import "./Library/IUnlockedERC721.sol";

contract VaultInternal is VerifySignature, Ownable {
    /*  
    ================================================================
                            State 
    ================================================================ 
    */

    uint256 public unlockDelay = 0;

    uint256 public timeUntilUnlockExpires = 1 minutes;

    mapping(address => bool) lockedERC721Exists;

    mapping(address => mapping(uint256 => uint256)) timestampForSingleNFTUnlocked;

    uint256 public timestampForAllNFTsUnlocked;

    address public backupAddressForEmergency;

    bool public hasOwner;

    /*  
    ================================================================
                            Modifers 
    ================================================================ 
    */

    modifier checkIsUnlocked(address unlockedERC721, uint256 tokenId) {
        if (!isTokenUnlocked(unlockedERC721, tokenId)) {
            require(isAllTokensUnlocked(), "Vault: Token is locked");
        }
        _;
    }

    modifier onlyBackupAddress() {
        require(
            backupAddressForEmergency == msg.sender,
            "Vault: this address is not the back up account"
        );
        _;
    }

    modifier checkValidSignature(bytes memory signature) {
        string memory message = "Invite";
        require(
            verify(owner(), backupAddressForEmergency, message, signature),
            "Vault: Signature is invalid"
        );
        _;
    }

    modifier checkLockedERC721Exists(address unlockedERC721) {
        if (!lockedERC721Exists[unlockedERC721]) {
            createLockedERC721(unlockedERC721);
        }
        _;
    }

    /*  
    ================================================================
                            Internal Functions 
    ================================================================ 
    */

    function isTokenUnlocked(address unlockedERC721, uint256 tokenId)
        internal
        returns (bool)
    {
        uint256 timeUnlocked = timestampForSingleNFTUnlocked[unlockedERC721][
            tokenId
        ];
        uint256 timeUnlockExpires = timeUnlocked + timeUntilUnlockExpires;
        return (block.timestamp >= timeUnlocked &&
            block.timestamp < timeUnlockExpires);
    }

    function isAllTokensUnlocked() internal returns (bool) {
        uint256 timeUnlocked = timestampForAllNFTsUnlocked;
        uint256 timeUnlockExpires = timeUnlocked + timeUntilUnlockExpires;
        return (block.timestamp >= timeUnlocked &&
            block.timestamp < timeUnlockExpires);
    }

    function burnLockedERC721(address unlockedERC721, uint256 tokenId)
        internal
    {
        if (LockedERC721(unlockedERC721).exists(tokenId)) {
            LockedERC721(unlockedERC721)._burnLockedERC721(tokenId);
        }
    }

    function mintLockedERC721(address unlockedERC721, uint256 tokenId)
        internal
    {
        LockedERC721(unlockedERC721)._mintLockedERC721(msg.sender, tokenId);
    }

    function transferERC721(address unlockedERC721, uint256 tokenId) internal {
        IUnlockedERC721 unlockedERC721 = IUnlockedERC721(unlockedERC721);
        if (unlockedERC721.ownerOf(tokenId) != address(this)) {
            unlockedERC721.safeTransferFrom(msg.sender, address(this), tokenId);
        }
    }

    function createLockedERC721(address unlockedERC721) internal {
        new LockedERC721(unlockedERC721);
        lockedERC721Exists[unlockedERC721] = true;
    }
}
