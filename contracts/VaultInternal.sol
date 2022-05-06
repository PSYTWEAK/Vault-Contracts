pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "./Library/VerifySignature.sol";
import "./LockedERC721.sol";
import "./Library/IUnlockedERC721.sol";

import "hardhat/console.sol";

/* 
$$\    $$\                    $$\   $$\     $$$$$$\            $$\                                             $$\ 
$$ |   $$ |                   $$ |  $$ |    \_$$  _|           $$ |                                            $$ |
$$ |   $$ |$$$$$$\  $$\   $$\ $$ |$$$$$$\     $$ |  $$$$$$$\ $$$$$$\    $$$$$$\   $$$$$$\  $$$$$$$\   $$$$$$\  $$ |
\$$\  $$  |\____$$\ $$ |  $$ |$$ |\_$$  _|    $$ |  $$  __$$\\_$$  _|  $$  __$$\ $$  __$$\ $$  __$$\  \____$$\ $$ |
 \$$\$$  / $$$$$$$ |$$ |  $$ |$$ |  $$ |      $$ |  $$ |  $$ | $$ |    $$$$$$$$ |$$ |  \__|$$ |  $$ | $$$$$$$ |$$ |
  \$$$  / $$  __$$ |$$ |  $$ |$$ |  $$ |$$\   $$ |  $$ |  $$ | $$ |$$\ $$   ____|$$ |      $$ |  $$ |$$  __$$ |$$ |
   \$  /  \$$$$$$$ |\$$$$$$  |$$ |  \$$$$  |$$$$$$\ $$ |  $$ | \$$$$  |\$$$$$$$\ $$ |      $$ |  $$ |\$$$$$$$ |$$ |
    \_/    \_______| \______/ \__|   \____/ \______|\__|  \__|  \____/  \_______|\__|      \__|  \__| \_______|\__|
    ___               _   ___      _   _           
   /   \___  __ _  __| | / __\   _| |_(_) ___  ___ 
  / /\ / _ \/ _` |/ _` |/ / | | | | __| |/ _ \/ __|
 / /_//  __/ (_| | (_| / /__| |_| | |_| |  __/\__ \
/___,' \___|\__,_|\__,_\____/\__,_|\__|_|\___||___/
*/

contract VaultInternal is VerifySignature, Ownable {
    /*  
    ================================================================
                            State 
    ================================================================ 
    */

    uint256 immutable unlockDelay = 24 hours;

    uint256 immutable timeUntilUnlockExpires = 2 hours;

    uint256 public currentUnlockedTimestampVersion;

    mapping(uint256 => mapping(address => mapping(uint256 => uint256))) whenSingleERC721Unlocked;

    uint256 public whenAllERC721Unlocked;

    mapping(address => address) lockedERC721Address;

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
        if (lockedERC721Address[unlockedERC721] == address(0)) {
            createLockedERC721(unlockedERC721);
        }
        _;
    }

    /*  
    ================================================================
                            Internal Functions 
    ================================================================ 
    */

    //========================= Withdraws ==============================

    function withdraw(address unlockedERC721, uint256 tokenId)
        internal
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
    ) internal {
        for (uint256 i; i < tokenIds.length; i++) {
            withdraw(unlockedERC721, tokenIds[i]);
        }
    }

    //========================= Deposits ==============================

    function deposit(address unlockedERC721, uint256 tokenId)
        internal
        checkLockedERC721Exists(unlockedERC721)
    {
        transferERC721(unlockedERC721, tokenId);
        mintLockedToken(unlockedERC721, tokenId);
    }

    function depositMutipleOfCollection(
        address unlockedERC721,
        uint256[] memory tokenIds
    ) internal {
        for (uint256 i; i < tokenIds.length; i++) {
            deposit(unlockedERC721, tokenIds[i]);
        }
    }

    //========================= LockedERC721 ==============================

    function createLockedERC721(address unlockedERC721) internal {
        LockedERC721 lockedERC721 = new LockedERC721(unlockedERC721);
        lockedERC721Address[unlockedERC721] = address(lockedERC721);
    }

    function mintLockedToken(address unlockedERC721, uint256 tokenId) internal {
        address lockedERC721 = lockedERC721Address[unlockedERC721];
        LockedERC721(lockedERC721)._mintLockedERC721(msg.sender, tokenId);
    }

    function burnLockedToken(address unlockedERC721, uint256 tokenId) internal {
        address lockedERC721 = lockedERC721Address[unlockedERC721];
        LockedERC721(lockedERC721)._burnLockedERC721(tokenId);
    }

    function resetAllSingleERC721Timestamps() internal {
        currentUnlockedTimestampVersion++;
    }

    function transferERC721(address unlockedERC721, uint256 tokenId) internal {
        IUnlockedERC721 unlockedERC721 = IUnlockedERC721(unlockedERC721);
        if (unlockedERC721.ownerOf(tokenId) != address(this)) {
            unlockedERC721.safeTransferFrom(msg.sender, address(this), tokenId);
        }
    }

    /*  
    ================================================================
                        Internal returns 
    ================================================================ 
    */

    function isTokenUnlocked(address unlockedERC721, uint256 tokenId)
        internal
        returns (bool)
    {
        uint256 timeUnlocked = whenSingleERC721Unlocked[
            currentUnlockedTimestampVersion
        ][unlockedERC721][tokenId];
        uint256 timeUnlockExpires = timeUnlocked + timeUntilUnlockExpires;

        return (block.timestamp >= timeUnlocked &&
            block.timestamp < timeUnlockExpires);
    }

    function isAllTokensUnlocked() internal returns (bool) {
        uint256 timeUnlocked = whenAllERC721Unlocked;
        uint256 timeUnlockExpires = timeUnlocked + timeUntilUnlockExpires;

        return (block.timestamp >= timeUnlocked &&
            block.timestamp < timeUnlockExpires);
    }
}
