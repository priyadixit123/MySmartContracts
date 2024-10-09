// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract DecentralizedSocialMedia {
    struct Post {
        uint256 id;
        address author;
        string content;
        uint256 likes;
    }

    struct User {
        address userAddress;
        string username;
        address[] followers;
        address[] following;
    }

    mapping(address => User) public users;
    mapping(uint256 => Post) public posts;
    mapping(address => mapping(uint256 => bool)) public likedPosts;

    uint256 public postCounter;

    event NewPost(address indexed author, uint256 postId, string content);
    event NewFollow(address indexed follower, address indexed followee);
    event PostLiked(address indexed liker, uint256 postId);

    // Register a user
    function registerUser(string memory _username) public {
        require(bytes(_username).length > 0, "Username cannot be empty");
        users, new address );
    }

    // Create a new post
    function createPost(string memory _content) public {
        require(bytes(users[msg.sender].username).length > 0, "User not registered");
        require(bytes(_content).length > 0, "Content cannot be empty");

        postCounter++;
        posts[postCounter] = Post(postCounter, msg.sender, _content, 0);

        emit NewPost(msg.sender, postCounter, _content);
    }

    // Follow another user
    function followUser(address _userToFollow) public {
        require(_userToFollow != msg.sender, "You cannot follow yourself");
        require(bytes(users[_userToFollow].username).length > 0, "User to follow does not exist");
        require(!isFollowing(msg.sender, _userToFollow), "Already following this user");

        users[msg.sender].following.push(_userToFollow);
        users[_userToFollow].followers.push(msg.sender);

        emit NewFollow(msg.sender, _userToFollow);
    }

    // Like a post
    function likePost(uint256 _postId) public {
        require(_postId > 0 && _postId <= postCounter, "Invalid post ID");
        require(!likedPosts[msg.sender][_postId], "Already liked this post");

        posts[_postId].likes++;
        likedPosts[msg.sender][_postId] = true;

        emit PostLiked(msg.sender, _postId);
    }

    // Helper function to check if a user is already following another user
    function isFollowing(address _follower, address _followee) public view returns (bool) {
        address[] memory followingList = users[_follower].following;
        for (uint256 i = 0; i < followingList.length; i++) {
            if (followingList[i] == _followee) {
                return true;
            }
        }
        return false;
    }

    // Get a user's followers count
    function getFollowersCount(address _user) public view returns (uint256) {
        return users[_user].followers.length;
    }

    // Get a user's following count
    function getFollowingCount(address _user) public view returns (uint256) {
        return users[_user].following.length;
    }

    // Get the number of likes on a post
    function getPostLikes(uint256 _postId) public view returns (uint256) {
        require(_postId > 0 && _postId <= postCounter, "Invalid post ID");
        return posts[_postId].likes;
    }
}
