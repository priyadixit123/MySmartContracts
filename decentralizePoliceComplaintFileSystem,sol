// SPDX-License-Identifier: MIT
 contract PoliceComplaint {

    struct Complaint {

       address complainant;
       string description;
       string status;
       uint256 timestamp;

   }

   address public policeStation;

   Complaint[] public complaints;

   mapping(address=>uint256[]) public userComplaints;

    modifier onlyPolice()
     { require(policeStation == msg.sender , "Only the police can perform this action.");
   _;

   }   

   constructor() {
    policeStation = msg.sender;
    }

    event ComplaintFiled(uint256 complaintId, address indexed complainant, string description, uint256 timestamp);
     event StatusUpdated (uint256 complaintId,string newStatus);
    function fileComplaint(string memory description) public {

        uint256 complaintId = complaints.length;
        complaints.push(Complaint({
            complainant : msg.sender,
            description : description,
            status : "Filed",
            timestamp : block.timestamp
        }));

        userComplaints[msg.sender].push(complaintId);
        emit ComplaintFiled(complaintId , msg.sender,description, block.timestamp);
    }

    function updateStatus (uint256 complaintId, string memory newStatus) public onlyPolice 
    {
        require(complaintId < complaints.length , "Invalid Complaint ID"); 
        complaints[complaintId].status = newStatus;
        emit StatusUpdated(complaintId , newStatus);
    }

    function getAllComplaints()public view returns (Complaint[] memory){
        return complaints;
    }
    function getUserComplaints(address user) public view returns (uint256[] memory){
        
            return userComplaints[user];
        }

      function getComplaintDetails(uint256 complaintId) public  view returns (Complaint memory)  
       {
          require(complaintId < complaints.length , "Invalid complaint ID");
          return complaints[complaintId];
       }
 }  
