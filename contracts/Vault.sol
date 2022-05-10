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

https://www.youtube.com/watch?v=3hoThry5WsY
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

    /**
     * Can be used to deposit multiple NFTs from multiple collections
     * into the vault in a single tx. All deposited NFTs will be
     * represented by wrapped instances sent to msg.sender eg 'lockedBoredApe'
     * @param unlockedERC721s list of contract addresses for the NFTs you are depositing
     * @param tokenIds list of lists of the NFT token Ids you are depositing
     */
    function deposit(
        address[] memory unlockedERC721s,
        uint256[][] memory tokenIds
    ) public onlyOwner {
        for (uint256 i; i < unlockedERC721s.length; i++) {
            depositMutipleOfCollection(unlockedERC721s[i], tokenIds[i]);
        }
    }

    /**
     * Can be used to withdraw multiple NFTs from the vault in a single tx
     * providing those tokens have been unlocked using either unlock() or unlockAll()
     * @param unlockedERC721s list of contract addresses for the NFTs you are withdrawing
     * @param tokenIds list of lists of the NFT token Ids you are withdrawing
     */
    function withdraw(
        address[] memory unlockedERC721s,
        uint256[][] memory tokenIds
    ) public onlyOwner {
        for (uint256 i; i < unlockedERC721s.length; i++) {
            withdrawMultipleOfCollection(unlockedERC721s[i], tokenIds[i]);
        }
    }

    /**
     * Unlock a specific token in the vault, keeping the rest locked.
     * @param unlockedERC721 contract address of the NFT you are unlocking
     * @param tokenId token id of the NFT you are unlocking
     */
    function unlock(address unlockedERC721, uint256 tokenId) public onlyOwner {
        whenSingleERC721Unlocked[currentUnlockedTimestampVersion][
            unlockedERC721
        ][tokenId] = block.timestamp + unlockDelay;
    }

    /**
     * Unlocks all tokens in the vault (includes all collections)
     */
    function unlockAll() public onlyOwner {
        whenAllERC721Unlocked = block.timestamp + unlockDelay;
    }

    /**
     * Locks every token in the vault regardless of if they have been unlocked
     * individually or via unlockAll()
     */
    function lockAll() public onlyOwner {
        whenAllERC721Unlocked = 0;
        resetAllSingleERC721Timestamps();
    }

    /**
     * Transfers control of the vault over to the backup address
     * this is to be used in emergencies when your private key has been compromised
     * trigger this before the anyone is able to unlock your tokens.
     * @param signature "Invite" hashed + signed by the owner on the vault off chain
     */
    function acceptEmergencyInviteForBackupAddressToTakeControl(
        bytes memory signature
    ) external onlyBackupAddress checkValidSignature(signature) {
        _transferOwnership(backupAddressForEmergency);
    }

    /**
     * Only used when initalising the vault
     */
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

    /**
     * Get the exact timestamp an NFT will be unlocked and withdrawable
     * @param unlockedERC721 contract address of the NFT
     * @param tokenId token id of the NFT
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

    /**
     * Get the exact timestamp all NFTs in the vault will be unlocked
     * and withdrawable
     */
    function getWhenAllERC721Unlocked() public view returns (uint256) {
        return whenAllERC721Unlocked;
    }

    /**
     * Gets the contracted address for the wrapped instant of
     * the NFTs locked in the vault eg 'lockedBoredApe'
     * @param unlockedERC721 contract address of the NFT inside the vault
     */
    function getLockedERC721(address unlockedERC721)
        public
        view
        returns (address)
    {
        return lockedERC721Address[unlockedERC721];
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
