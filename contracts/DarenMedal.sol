// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/access/AccessControlEnumerableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/ERC721Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/extensions/ERC721EnumerableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/math/SafeMathUpgradeable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import "./interfaces/IDarenMedal.sol";

contract DarenMedal is
    IDarenMedal,
    ERC721EnumerableUpgradeable,
    AccessControlEnumerableUpgradeable
{
    using SafeMathUpgradeable for uint256;

    bytes32 public constant ADMIN_ROLE = keccak256("ADMIN_ROLE");

    uint256 private primaryKey; // Order index
    mapping(uint256 => Order) public orders;

    uint256 public feeRatio; // default: 2.5%
    uint256 public feeRatioBase; // default: 10000
    address public feeTo;

    mapping(address => uint256) public staking; // address1 => tokenId
    mapping(address => uint256) public stakingEndTime;
    uint256 public minimumStakingTime; // In days

    function initialize() public initializer {
        __ERC721_init("Daren Medal", "DM");
        __ERC721Enumerable_init();
        __AccessControlEnumerable_init();

        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _setupRole(ADMIN_ROLE, msg.sender);

        feeRatio = 250; // ratio base is 10000, 250 => 250 / 10000 => 2.5%
        feeRatioBase = 10000;
        feeTo = msg.sender;

        minimumStakingTime = 7;
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(
            ERC721EnumerableUpgradeable,
            AccessControlEnumerableUpgradeable
        )
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return "";
    }

    function stake(uint256 _tokenId) external {
        require(staking[msg.sender] == 0, "You have already staked.");
        require(ownerOf(_tokenId) == msg.sender, "You are not the owner.");
        require(
            !orderOnSale(_tokenId),
            "You cannot stake the NFT while selling."
        );

        transferFrom(msg.sender, address(this), _tokenId);
        staking[msg.sender] = _tokenId;
        stakingEndTime[msg.sender] =
            block.timestamp +
            minimumStakingTime *
            1 days;
    }

    function unstake() external {
        require(staking[msg.sender] > 0, "You do not have NFTs in staking.");
        require(
            block.timestamp > stakingEndTime[msg.sender],
            "Unable to unstake."
        );

        _transfer(address(this), msg.sender, staking[msg.sender]);
        staking[msg.sender] = 0;
    }

    // Market ===================================
    function orderOnSale(uint256 _tokenId) public view returns (bool) {
        Order memory order = orders[_tokenId];

        return order.pk > 0;
    }

    // Override =================================
    function transfer(
        address from,
        address to,
        uint256 tokenId
    ) external {
        require(!orderOnSale(tokenId), "The NFT is on sale.");
        require(
            staking[msg.sender] != tokenId,
            "Can not transfer NFTs in staking."
        );

        _transfer(from, to, tokenId);
    }

    function setMinimumStakingTime(uint256 _minimumStakingTime)
        external
        onlyRole(ADMIN_ROLE)
    {
        require(
            _minimumStakingTime > 0,
            "Minimum staking time should be greater than 0."
        );
        minimumStakingTime = _minimumStakingTime;
    }

    function getPrimaryKey()
        public
        view
        onlyRole(ADMIN_ROLE)
        returns (uint256)
    {
        return primaryKey;
    }
}
