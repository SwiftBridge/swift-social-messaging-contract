// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

/**
 * @title SocialMessaging
 * @dev A decentralized social messaging contract for Swift v2
 * @author Swift v2 Team
 */
contract SocialMessaging is ReentrancyGuard, Ownable {
    using Counters for Counters.Counter;
    using Strings for uint256;

    // Events
    event MessageSent(
        uint256 indexed messageId,
        address indexed sender,
        address indexed recipient,
        string content,
        uint256 timestamp,
        string messageType
    );

    event MessageDeleted(
        uint256 indexed messageId,
        address indexed sender,
        address indexed recipient
    );

    event UserBlocked(
        address indexed blocker,
        address indexed blockedUser
    );

    event UserUnblocked(
        address indexed blocker,
        address indexed blockedUser
    );

    event MessageReported(
        uint256 indexed messageId,
        address indexed reporter,
        string reason
    );

    // Structs
    struct Message {
        uint256 id;
        address sender;
        address recipient;
        string content;
        uint256 timestamp;
        string messageType;
        bool isDeleted;
        bool isReported;
    }

    struct UserProfile {
        string username;
        string bio;
        string avatar;
        bool isActive;
        uint256 joinedAt;
        uint256 lastSeen;
    }

    struct Conversation {
        address participant1;
        address participant2;
        uint256 lastMessageId;
        uint256 createdAt;
        bool isActive;
    }

    // State variables
    Counters.Counter private _messageIdCounter;
    Counters.Counter private _conversationIdCounter;

    mapping(uint256 => Message) public messages;
    mapping(address => UserProfile) public userProfiles;
    mapping(address => mapping(address => bool)) public blockedUsers;
    mapping(address => mapping(address => bool)) public isFollowing;
    mapping(address => uint256[]) public userMessages;
    mapping(address => mapping(address => uint256)) public conversationIds;
    mapping(uint256 => Conversation) public conversations;
    mapping(address => uint256[]) public userConversations;
    mapping(uint256 => address[]) public messageReports;

    // Constants
    uint256 public constant MAX_MESSAGE_LENGTH = 1000;
    uint256 public constant MAX_USERNAME_LENGTH = 50;
    uint256 public constant MAX_BIO_LENGTH = 200;
    uint256 public constant MESSAGE_FEE = 0.000003 ether; // Optional fee for premium features (~$0.009 at $3000 ETH)

    // Modifiers
    modifier onlyActiveUser() {
        require(userProfiles[msg.sender].isActive, "User not active");
        _;
    }

    modifier validMessageLength(string memory _content) {
        require(bytes(_content).length <= MAX_MESSAGE_LENGTH, "Message too long");
        require(bytes(_content).length > 0, "Message cannot be empty");
        _;
    }

    modifier notBlocked(address _recipient) {
        require(!blockedUsers[_recipient][msg.sender], "You are blocked by this user");
        require(!blockedUsers[msg.sender][_recipient], "You have blocked this user");
        _;
    }

    modifier messageExists(uint256 _messageId) {
        require(_messageId > 0 && _messageId <= _messageIdCounter.current(), "Message does not exist");
        _;
    }

    constructor() {
        // Initialize counters
        _messageIdCounter.increment(); // Start from 1
        _conversationIdCounter.increment(); // Start from 1
    }

    /**
     * @dev Create or update user profile
     * @param _username User's display name
     * @param _bio User's bio
     * @param _avatar User's avatar URL
     */
    function createProfile(
        string memory _username,
        string memory _bio,
        string memory _avatar
    ) external {
        require(bytes(_username).length <= MAX_USERNAME_LENGTH, "Username too long");
        require(bytes(_bio).length <= MAX_BIO_LENGTH, "Bio too long");
        require(bytes(_username).length > 0, "Username cannot be empty");

        UserProfile storage profile = userProfiles[msg.sender];
        
        if (profile.joinedAt == 0) {
            profile.joinedAt = block.timestamp;
        }
        
        profile.username = _username;
        profile.bio = _bio;
        profile.avatar = _avatar;
        profile.isActive = true;
        profile.lastSeen = block.timestamp;
    }

    /**
     * @dev Send a message to another user
     * @param _recipient Address of the recipient
     * @param _content Message content
     * @param _messageType Type of message (text, image, file, etc.)
     */
    function sendMessage(
        address _recipient,
        string memory _content,
        string memory _messageType
    ) 
        external 
        payable 
        nonReentrant 
        onlyActiveUser 
        validMessageLength(_content)
        notBlocked(_recipient)
    {
        require(_recipient != address(0), "Invalid recipient");
        require(_recipient != msg.sender, "Cannot send message to yourself");
        require(userProfiles[_recipient].isActive, "Recipient not active");

        // Optional fee for premium features
        if (msg.value > 0) {
            require(msg.value >= MESSAGE_FEE, "Insufficient fee");
        }

        uint256 messageId = _messageIdCounter.current();
        _messageIdCounter.increment();

        Message storage newMessage = messages[messageId];
        newMessage.id = messageId;
        newMessage.sender = msg.sender;
        newMessage.recipient = _recipient;
        newMessage.content = _content;
        newMessage.timestamp = block.timestamp;
        newMessage.messageType = _messageType;
        newMessage.isDeleted = false;
        newMessage.isReported = false;

        // Add message to user's message list
        userMessages[msg.sender].push(messageId);
        userMessages[_recipient].push(messageId);

        // Create or update conversation
        _createOrUpdateConversation(msg.sender, _recipient, messageId);

        // Update last seen
        userProfiles[msg.sender].lastSeen = block.timestamp;

        emit MessageSent(messageId, msg.sender, _recipient, _content, block.timestamp, _messageType);
    }

    /**
     * @dev Delete a message (only sender can delete)
     * @param _messageId ID of the message to delete
     */
    function deleteMessage(uint256 _messageId) 
        external 
        messageExists(_messageId)
    {
        Message storage message = messages[_messageId];
        require(message.sender == msg.sender, "Only sender can delete message");
        require(!message.isDeleted, "Message already deleted");

        message.isDeleted = true;

        emit MessageDeleted(_messageId, message.sender, message.recipient);
    }

    /**
     * @dev Block a user
     * @param _user Address of the user to block
     */
    function blockUser(address _user) external onlyActiveUser {
        require(_user != address(0), "Invalid user");
        require(_user != msg.sender, "Cannot block yourself");
        require(!blockedUsers[msg.sender][_user], "User already blocked");

        blockedUsers[msg.sender][_user] = true;

        emit UserBlocked(msg.sender, _user);
    }

    /**
     * @dev Unblock a user
     * @param _user Address of the user to unblock
     */
    function unblockUser(address _user) external onlyActiveUser {
        require(_user != address(0), "Invalid user");
        require(blockedUsers[msg.sender][_user], "User not blocked");

        blockedUsers[msg.sender][_user] = false;

        emit UserUnblocked(msg.sender, _user);
    }

    /**
     * @dev Follow a user
     * @param _user Address of the user to follow
     */
    function followUser(address _user) external onlyActiveUser {
        require(_user != address(0), "Invalid user");
        require(_user != msg.sender, "Cannot follow yourself");
        require(userProfiles[_user].isActive, "User not active");

        isFollowing[msg.sender][_user] = true;
    }

    /**
     * @dev Unfollow a user
     * @param _user Address of the user to unfollow
     */
    function unfollowUser(address _user) external onlyActiveUser {
        require(_user != address(0), "Invalid user");
        require(isFollowing[msg.sender][_user], "Not following this user");

        isFollowing[msg.sender][_user] = false;
    }

    /**
     * @dev Report a message
     * @param _messageId ID of the message to report
     * @param _reason Reason for reporting
     */
    function reportMessage(uint256 _messageId, string memory _reason) 
        external 
        messageExists(_messageId)
    {
        Message storage message = messages[_messageId];
        require(message.recipient == msg.sender || message.sender == msg.sender, "Not authorized to report this message");
        require(!message.isReported, "Message already reported");

        message.isReported = true;
        messageReports[_messageId].push(msg.sender);

        emit MessageReported(_messageId, msg.sender, _reason);
    }

    /**
     * @dev Get user's messages
     * @param _user Address of the user
     * @param _offset Starting index
     * @param _limit Number of messages to return
     * @return Array of message IDs
     */
    function getUserMessages(
        address _user,
        uint256 _offset,
        uint256 _limit
    ) public view returns (uint256[] memory) {
        uint256[] memory userMessageIds = userMessages[_user];
        uint256 length = userMessageIds.length;
        
        if (_offset >= length) {
            return new uint256[](0);
        }

        uint256 end = _offset + _limit;
        if (end > length) {
            end = length;
        }

        uint256[] memory result = new uint256[](end - _offset);
        for (uint256 i = _offset; i < end; i++) {
            result[i - _offset] = userMessageIds[i];
        }

        return result;
    }

    /**
     * @dev Get conversation between two users
     * @param _user1 First user address
     * @param _user2 Second user address
     * @param _offset Starting index
     * @param _limit Number of messages to return
     * @return Array of message IDs
     */
    function getConversation(
        address _user1,
        address _user2,
        uint256 _offset,
        uint256 _limit
    ) external view returns (uint256[] memory) {
        uint256 conversationId = conversationIds[_user1][_user2];
        if (conversationId == 0) {
            return new uint256[](0);
        }

        // This is a simplified implementation
        // In a production system, you'd want to store conversation messages separately
        return getUserMessages(_user1, _offset, _limit);
    }

    /**
     * @dev Get message details
     * @param _messageId ID of the message
     * @return Message struct
     */
    function getMessage(uint256 _messageId) 
        external 
        view 
        messageExists(_messageId)
        returns (Message memory)
    {
        return messages[_messageId];
    }

    /**
     * @dev Get user profile
     * @param _user Address of the user
     * @return UserProfile struct
     */
    function getUserProfile(address _user) external view returns (UserProfile memory) {
        return userProfiles[_user];
    }

    /**
     * @dev Check if user is blocked
     * @param _blocker Address of the potential blocker
     * @param _blocked Address of the potentially blocked user
     * @return True if blocked
     */
    function isUserBlocked(address _blocker, address _blocked) external view returns (bool) {
        return blockedUsers[_blocker][_blocked];
    }

    /**
     * @dev Check if user is following another user
     * @param _follower Address of the follower
     * @param _following Address of the user being followed
     * @return True if following
     */
    function isUserFollowing(address _follower, address _following) external view returns (bool) {
        return isFollowing[_follower][_following];
    }

    /**
     * @dev Get total message count
     * @return Total number of messages
     */
    function getTotalMessageCount() external view returns (uint256) {
        return _messageIdCounter.current() - 1;
    }

    /**
     * @dev Get user's message count
     * @param _user Address of the user
     * @return Number of messages
     */
    function getUserMessageCount(address _user) external view returns (uint256) {
        return userMessages[_user].length;
    }

    /**
     * @dev Internal function to create or update conversation
     * @param _user1 First user address
     * @param _user2 Second user address
     * @param _messageId ID of the latest message
     */
    function _createOrUpdateConversation(
        address _user1,
        address _user2,
        uint256 _messageId
    ) internal {
        uint256 conversationId = conversationIds[_user1][_user2];
        
        if (conversationId == 0) {
            conversationId = _conversationIdCounter.current();
            _conversationIdCounter.increment();
            
            Conversation storage newConversation = conversations[conversationId];
            newConversation.participant1 = _user1;
            newConversation.participant2 = _user2;
            newConversation.createdAt = block.timestamp;
            newConversation.isActive = true;
            
            conversationIds[_user1][_user2] = conversationId;
            conversationIds[_user2][_user1] = conversationId;
            
            userConversations[_user1].push(conversationId);
            userConversations[_user2].push(conversationId);
        }
        
        conversations[conversationId].lastMessageId = _messageId;
    }

    /**
     * @dev Withdraw contract balance (only owner)
     */
    function withdraw() external onlyOwner nonReentrant {
        uint256 balance = address(this).balance;
        require(balance > 0, "No balance to withdraw");

        (bool success, ) = payable(owner()).call{value: balance}("");
        require(success, "Withdraw failed");
    }

    /**
     * @dev Emergency pause function (only owner)
     */
    function pause() external onlyOwner {
        // Implementation would depend on OpenZeppelin's Pausable contract
        // This is a placeholder for emergency functionality
    }
}
