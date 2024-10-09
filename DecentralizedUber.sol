// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IERC20 {
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function balanceOf(address account) external view returns (uint256);
}

contract DecentralizedUber {
    struct Ride {
        address rider;
        address driver;
        uint256 fare;
        bool isCompleted;
        bool isAccepted;
        bool isCancelled;
        uint256 startTime;
    }

    struct Rating {
        uint256 totalRatings;
        uint256 numberOfRatings;
    }

    IERC20 public token;  // ERC20 token contract address
    uint256 public cancellationPenalty = 5;  // Penalty percentage for cancellations

    // Track driver availability
    mapping(address => bool) public driverAvailability;

    // Mapping for ride requests and ratings
    mapping(uint256 => Ride) public rides;
    mapping(address => Rating) public riderRatings;
    mapping(address => Rating) public driverRatings;
    uint256 public rideCounter;

    // Mapping for ride history
    mapping(address => uint256[]) public rideHistory;

    // Events
    event RideRequested(uint256 rideId, address indexed rider, uint256 fare);
    event RideAccepted(uint256 rideId, address indexed driver);
    event RideCompleted(uint256 rideId, address indexed rider, address indexed driver);
    event RideCancelled(uint256 rideId, address indexed cancelledBy);
    event RatingSubmitted(address indexed ratedAddress, uint256 rating);

    // Constructor to initialize the token contract
    constructor(IERC20 _token) {
        token = _token;
    }

    // Modifier to check if driver is available
    modifier onlyAvailableDriver() {
        require(driverAvailability[msg.sender], "Driver is not available");
        _;
    }

    // Set driver availability
    function setDriverAvailability(bool _isAvailable) public {
        driverAvailability[msg.sender] = _isAvailable;
    }

    // Request a ride using ERC20 tokens
    function requestRide(uint256 _fare) public {
        require(_fare > 0, "Fare must be greater than zero");

        rideCounter++;
        rides[rideCounter] = Ride({
            rider: msg.sender,
            driver: address(0),
            fare: _fare,
            isCompleted: false,
            isAccepted: false,
            isCancelled: false,
            startTime: 0
        });

        rideHistory[msg.sender].push(rideCounter);

        emit RideRequested(rideCounter, msg.sender, _fare);
    }

    // Accept a ride
    function acceptRide(uint256 _rideId) public onlyAvailableDriver {
        Ride storage ride = rides[_rideId];
        require(ride.rider != address(0), "Ride does not exist");
        require(!ride.isAccepted, "Ride already accepted");
        require(!ride.isCancelled, "Ride has been cancelled");
        require(!ride.isCompleted, "Ride already completed");

        ride.driver = msg.sender;
        ride.isAccepted = true;
        ride.startTime = block.timestamp;

        rideHistory[msg.sender].push(_rideId);

        emit RideAccepted(_rideId, msg.sender);
    }

    // Complete a ride and transfer ERC20 tokens as payment
    function completeRide(uint256 _rideId) public {
        Ride storage ride = rides[_rideId];
        require(ride.rider == msg.sender, "Only the rider can complete the ride");
        require(ride.isAccepted, "Ride must be accepted before completing");
        require(!ride.isCompleted, "Ride already completed");
        require(!ride.isCancelled, "Ride has been cancelled");

        ride.isCompleted = true;

        // Transfer fare to the driver using ERC20 tokens
        require(token.transferFrom(ride.rider, ride.driver, ride.fare), "Token transfer failed");

        emit RideCompleted(_rideId, ride.rider, ride.driver);
    }

    // Cancel a ride (either by rider or driver)
    function cancelRide(uint256 _rideId) public {
        Ride storage ride = rides[_rideId];
        require(!ride.isCompleted, "Ride already completed");
        require(!ride.isCancelled, "Ride already cancelled");
        require(ride.rider == msg.sender || ride.driver == msg.sender, "Only the rider or driver can cancel the ride");

        ride.isCancelled = true;

        // Apply penalty if the ride is cancelled after acceptance
        if (ride.isAccepted && block.timestamp > ride.startTime + 10 minutes) {
            uint256 penaltyAmount = (ride.fare * cancellationPenalty) / 100;
            if (msg.sender == ride.rider) {
                // Rider cancels: Penalty is paid to the driver
                require(token.transferFrom(ride.rider, ride.driver, penaltyAmount), "Token transfer failed");
            } else {
                // Driver cancels: Penalty is paid to the rider
                require(token.transferFrom(ride.driver, ride.rider, penaltyAmount), "Token transfer failed");
            }
        }

        emit RideCancelled(_rideId, msg.sender);
    }

    // Submit a rating for driver or rider (1 to 5 scale)
    function submitRating(address _user, uint256 _rating) public {
        require(_rating >= 1 && _rating <= 5, "Rating must be between 1 and 5");

        if (msg.sender == rides[rideCounter].rider) {
            // Rider is rating driver
            driverRatings[_user].totalRatings += _rating;
            driverRatings[_user].numberOfRatings += 1;
        } else if (msg.sender == rides[rideCounter].driver) {
            // Driver is rating rider
            riderRatings[_user].totalRatings += _rating;
            riderRatings[_user].numberOfRatings += 1;
        } else {
            revert("Only participants of the ride can rate each other");
        }

        emit RatingSubmitted(_user, _rating);
    }

    // Get the aggregated average rating for a user
    function getUserRating(address _user) public view returns (uint256) {
        Rating storage rating = driverRatings[_user];
        if (rating.numberOfRatings > 0) {
            return rating.totalRatings / rating.numberOfRatings;
        }
        rating = riderRatings[_user];
        require(rating.numberOfRatings > 0, "No ratings available for this user");
        return rating.totalRatings / rating.numberOfRatings;
    }

    // View ride history for a user
    function getRideHistory(address _user) public view returns (uint256[] memory) {
        return rideHistory[_user];
    }
}
