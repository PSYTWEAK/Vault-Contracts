pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import "./VerifySignature.sol";
import "./LockedERC721.sol";

/* 
Yb    dP    db    88   88 88     888888 
 Yb  dP    dPYb   88   88 88       88   
  YbdP    dP__Yb  Y8   8P 88  .o   88   
   YP    dP""""Yb `YbodP' 88ood8   88  
*/

contract Vault is Ownable, VerifySignature {
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
                            Contructor 
    ================================================================ 
    */

    constructor(address _backupAddressForEmergency) {
        backupAddressForEmergency = _backupAddressForEmergency;
    }

    /*  
    ================================================================
                    Only owner external Functions 
    ================================================================ 
    */

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
        _burnLockedERC721(tokenId);
        ERC721Addr.safeTransferFrom(address(this), msg.sender, tokenId);
    }

    function withdrawMultiple(uint256[] memory tokenId) external onlyOwner {
        for (uint256 i; i < tokenId.length; i++) {
            withdraw(tokenId[i]);
        }
    }

    function deposit(uint256 tokenId, address ERC721Addr)
        external
        onlyOwner
        checkLockedERC721Exists(ERC721Addr)
    {
        transferERC721(tokenId, ERC721Addr);
        _mintLockedERC721(tokenId);
    }

    /*  
    ================================================================
            Emergency Owner and Backup address Functions 
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

    function _burnLockedERC721(uint256 tokenId, address ERC721Addr) internal {
        if (LockedERC721(tokenId) == msg.sender) {
            LockedERC721(ERC721Addr).burnLockedERC721(tokenId);
        }
    }

    function _mintLockedERC721(uint256 tokenId, address ERC721Addr) internal {
        LockedERC721(ERC721Addr).mintLockedERC721(msg.sender, tokenId);
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

    /*  
    ================================================================
                        Public View Functions 
    ================================================================ 
    */

    function tokenURI(uint256 tokenId, address ERC721Addr)
        public
        view
        override
        returns (string memory)
    {
        return IERC721(ERC721Addr).tokenURI(tokenId);
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
