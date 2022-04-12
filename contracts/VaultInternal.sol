pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "./Library/VerifySignature.sol";
import "./LockedERC721.sol";

contract VaultInternal is VerifySignature, Ownable {
    /*  
    ================================================================
                            State 
    ================================================================ 
    */

    uint256 public unlockDelay = 0;

    uint256 public timeUntilUnlockExpires = 1 minutes;

    mapping(address => mapping(uint256 => uint256)) timeUntilSingleNFTUnlocked;

    mapping(address => mapping(address => LockedERC721)) lockedERC721Addresses;

    uint256 public timeUntilAllUnlocked;

    address public backupAddressForEmergency;

    bool public hasOwner;

    /*  
    ================================================================
                            Modifers 
    ================================================================ 
    */

    modifier checkIsUnlocked(uint256 tokenId, address ERC721Addr) {
        if (!isTokenUnlocked(tokenId, ERC721Addr)) {
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

    modifier checkLockedERC721Exists(address ERC721Addr) {
        address lockedERC721 = lockedERC721Addresses[msg.sender][ERC721Addr];
        if (!lockedERC721) {
            createLockedERC721(ERC721Addr);
        }
        _;
    }

    /*  
    ================================================================
                            Internal Functions 
    ================================================================ 
    */

    function isTokenUnlocked(uint256 tokenId, address ERC721Addr)
        internal
        returns (bool)
    {
        uint256 timeUnlocked = timeUntilSingleNFTUnlocked[ERC721Addr][tokenId];
        uint256 timeUnlockExpires = timeUnlocked + timeUntilUnlockExpires;
        return (block.timestamp >= timeUnlocked &&
            block.timestamp < timeUnlockExpires);
    }

    function isAllTokensUnlocked() internal returns (bool) {
        uint256 timeUnlocked = timeUntilAllUnlocked;
        uint256 timeUnlockExpires = timeUnlocked + timeUntilUnlockExpires;
        return (block.timestamp >= timeUnlocked &&
            block.timestamp < timeUnlockExpires);
    }

    function burnLockedERC721(uint256 tokenId, address ERC721Addr) internal {
        if (LockedERC721(ERC721Addr).exists(tokenId) == msg.sender) {
            LockedERC721(ERC721Addr)._burnLockedERC721(tokenId);
        }
    }

    function mintLockedERC721(uint256 tokenId, address ERC721Addr) internal {
        LockedERC721(ERC721Addr)._mintLockedERC721(msg.sender, tokenId);
    }

    function transferERC721(uint256 tokenId, address ERC721Addr) internal {
        IERC721 ERC721 = IERC721(ERC721Addr);
        if (ERC721.ownerOf(tokenId) != address(this)) {
            ERC721.safeTransferFrom(msg.sender, address(this), tokenId);
        }
    }

    function createLockedERC721(address ERC721Address) internal {
        LockedERC721 lockedERC721 = new LockedERC721(ERC721Address);
        lockedERC721Addresses[msg.sender][ERC721Address] = address(
            lockedERC721
        );
    }
}
