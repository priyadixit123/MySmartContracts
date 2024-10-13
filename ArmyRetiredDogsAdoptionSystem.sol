// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract ArmyRetiredDogRegistry {

    // Structure to represent a retired army dog
    struct RetiredDog {
    string originalName;        // Dog's original name while in service
    string newName;             // Dog's new name after retirement
    string breed;               // Breed of the dog
    uint256 age;                // Age of the dog
    string serviceRecord;       // Brief summary of the dog's service record
    bool isAdopted;             // Status indicating if the dog has been adopted
    address owner;              // The address of the current owner (if adopted)
    uint256 totalDonations;     // Total donations for this dog
    string[] veterinaryRecords; // List of veterinary records (corrected to string[])
} 

    // Address of the police station/official (contract owner)
    address public policeStation;
    
    // Adoption fee for adopting a dog
    uint256 public adoptionFee = 0.01 ether;

    // List of all retired army dogs
    RetiredDog[] public retiredDogs;

    // Mapping to keep track of donations made for a specific dog
    mapping(uint256 => uint256) public dogDonations;

    // Mapping to track the dog adoption history
    mapping(uint256 => address[]) public adoptionHistory;

    // Event emitted when a new dog is added to the registry
    event DogAdded(uint256 dogId, string originalName, string breed, uint256 age);

    // Event emitted when a dog is adopted and given a new name
    event DogAdopted(uint256 dogId, address adopter, string newName);

    // Event emitted when ownership of a dog is transferred
    event OwnershipTransferred(uint256 dogId, address oldOwner, address newOwner);

    // Event emitted when donations are made for a dog
    event DonationMade(uint256 dogId, address donor, uint256 amount);

    // Event emitted when a veterinary record is added
    event VeterinaryRecordAdded(uint256 dogId, string record);

    // Modifier to ensure that only the dog's owner can update or transfer the dog
    modifier onlyOwner(uint256 dogId) {
        require(retiredDogs[dogId].owner == msg.sender, "Only the dog's owner can perform this action.");
        _;
    }

    // Modifier to ensure that only police can perform certain actions
    modifier onlyPolice() {
        require(msg.sender == policeStation, "Only the police can perform this action.");
        _;
    }

    // Constructor: Sets the police station's address
    constructor() {
        policeStation = msg.sender;
    }

    // Function to add a retired dog to the registry
    function addRetiredDog(
        string memory _originalName,
        string memory _breed,
        uint256 _age,
        string memory _serviceRecord
    ) public onlyPolice {
        uint256 dogId = retiredDogs.length;
        retiredDogs.push(RetiredDog({
    originalName: _originalName,
    newName: "",
    breed: _breed,
    age: _age,
    serviceRecord: _serviceRecord,
    isAdopted: false,
    owner: address(0),
    totalDonations: 0,
    veterinaryRecords: new string[](0)
    }));

        emit DogAdded(dogId, _originalName, _breed, _age);
    }

    // Function to adopt a retired dog and assign a new name (requires payment of an adoption fee)
    function adoptDog(uint256 dogId, string memory _newName) public payable {
        require(dogId < retiredDogs.length, "Invalid dog ID.");
        require(!retiredDogs[dogId].isAdopted, "This dog has already been adopted.");
        require(msg.value >= adoptionFee, "Adoption fee not met.");

        RetiredDog storage dog = retiredDogs[dogId];
        dog.isAdopted = true;
        dog.newName = _newName;
        dog.owner = msg.sender;

        // Track adoption history
        adoptionHistory[dogId].push(msg.sender);

        emit DogAdopted(dogId, msg.sender, _newName);
    }

    // Function to transfer ownership of an adopted dog
    function transferOwnership(uint256 dogId, address newOwner) public onlyOwner(dogId) {
        require(newOwner != address(0), "Invalid new owner address.");
        address oldOwner = retiredDogs[dogId].owner;
        retiredDogs[dogId].owner = newOwner;

        // Update adoption history
        adoptionHistory[dogId].push(newOwner);

        emit OwnershipTransferred(dogId, oldOwner, newOwner);
    }

    // Function to donate for a specific dog
    function donateForDog(uint256 dogId) public payable {
        require(dogId < retiredDogs.length, "Invalid dog ID.");
        retiredDogs[dogId].totalDonations += msg.value;
        dogDonations[dogId] += msg.value;

        emit DonationMade(dogId, msg.sender, msg.value);
    }

    // Function to add veterinary record for the dog (owner or police can add)
    function addVeterinaryRecord(uint256 dogId, string memory record) public {
    require(dogId < retiredDogs.length, "Invalid dog ID.");
    require(msg.sender == retiredDogs[dogId].owner || msg.sender == policeStation, "Not authorized to add record.");

    retiredDogs[dogId].veterinaryRecords.push(record);  // Add a new record to the array (corrected)
    
    emit VeterinaryRecordAdded(dogId, record);
}

    // Function to get details of a specific retired dog
    function getDogDetails(uint256 dogId) public view returns (
        string memory originalName,
        string memory newName,
        string memory breed,
        uint256 age,
        string memory serviceRecord,
        bool isAdopted,
        address owner,
        uint256 totalDonations,
        string[] memory veterinaryRecords
    ) {
        require(dogId < retiredDogs.length, "Invalid dog ID.");
        RetiredDog memory dog = retiredDogs[dogId];

        return (
            dog.originalName,
            dog.newName,
            dog.breed,
            dog.age,
            dog.serviceRecord,
            dog.isAdopted,
            dog.owner,
            dog.totalDonations,
            dog.veterinaryRecords
        );
    }

    // Function to get all the adoption history of a dog
    function getAdoptionHistory(uint256 dogId) public view returns (address[] memory) {
        return adoptionHistory[dogId];
    }

    // Function to withdraw funds (only police can withdraw)
    function withdrawFunds() public onlyPolice {
        payable(policeStation).transfer(address(this).balance);
    }
}
