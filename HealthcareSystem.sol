// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract HealthcareSystem {

    // Struct for patients
    struct Patient {
        address patientAddress;
        string name;
        uint age;
        string medicalHistory;
        string[] medicalReports;  // Links to medical reports stored on IPFS
        uint tokenBalance;  // Token balance as a reward for sharing data
        bool isRegistered;
    }

    // Struct for doctors
    struct Doctor {
        address doctorAddress;
        string name;
        string specialization;
        uint rating;  // Patient rating system
        uint totalRatings;
        uint numberOfRatings;
        bool isApproved;
    }

    // Struct for appointments
    struct Appointment {
        address patientAddress;
        address doctorAddress;
        uint date;
        bool isBooked;
        bool isCompleted;
    }

    // Struct for insurance claims
    struct InsuranceClaim {
        address patientAddress;
        address insurer;
        uint claimAmount;
        bool isApproved;
        bool isPaid;
    }

    // Admin address for managing doctors
    address public admin;

    // Token for patient incentives
    uint public tokenReward = 100;  // Token reward for sharing medical data

    // Mappings to store patients, doctors, appointments, insurance claims
    mapping(address => Patient) public patients;
    mapping(address => Doctor) public doctors;
    mapping(uint => Appointment) public appointments;
    mapping(uint => InsuranceClaim) public claims;

    // Appointment index
    uint public appointmentIndex;

    // Insurance claim index
    uint public claimIndex;

    // Events
    event PatientRegistered(address indexed patient, string name);
    event DoctorApproved(address indexed doctor, string name);
    event AppointmentBooked(uint indexed appointmentId, address indexed patient, address indexed doctor);
    event AppointmentCancelled(uint indexed appointmentId);
    event ReportUploaded(address indexed patient, string ipfsHash);
    event InsuranceClaimFiled(uint indexed claimId, address indexed patient, uint amount);
    event InsuranceClaimApproved(uint indexed claimId);
    event RewardTokensIssued(address indexed patient, uint amount);

    // Modifier to restrict to admin
    modifier onlyAdmin() {
        require(msg.sender == admin, "Only admin can perform this action.");
        _;
    }

    // Modifier to restrict to registered patients
    modifier onlyRegisteredPatient() {
        require(patients[msg.sender].isRegistered, "Patient not registered.");
        _;
    }

    // Modifier to restrict to approved doctors
    modifier onlyApprovedDoctor() {
        require(doctors[msg.sender].isApproved, "Doctor not approved.");
        _;
    }

    constructor() {
        admin = msg.sender;
    }

    // Patient registration function
    function registerPatient(string memory _name, uint _age, string memory _medicalHistory) public {
        require(!patients[msg.sender].isRegistered, "Patient already registered.");
        patients, 0, true);
        emit PatientRegistered(msg.sender, _name);
    }

    // Admin function to approve doctors
    function approveDoctor(address _doctorAddress, string memory _name, string memory _specialization) public onlyAdmin {
        require(!doctors[_doctorAddress].isApproved, "Doctor already approved.");
        doctors[_doctorAddress] = Doctor(_doctorAddress, _name, _specialization, 0, 0, 0, true);
        emit DoctorApproved(_doctorAddress, _name);
    }

    // Function for booking an appointment
    function bookAppointment(address _doctorAddress, uint _date) public onlyRegisteredPatient {
        require(doctors[_doctorAddress].isApproved, "Doctor not approved.");
        appointments[appointmentIndex] = Appointment(msg.sender, _doctorAddress, _date, true, false);
        emit AppointmentBooked(appointmentIndex, msg.sender, _doctorAddress);
        appointmentIndex++;
    }

    // Function for cancelling an appointment
    function cancelAppointment(uint _appointmentId) public {
        Appointment storage appointment = appointments[_appointmentId];
        require(appointment.patientAddress == msg.sender, "You can only cancel your own appointment.");
        require(appointment.isBooked, "Appointment not booked.");
        appointment.isBooked = false;
        emit AppointmentCancelled(_appointmentId);
    }

    // Function to upload medical reports to IPFS
    function uploadReport(string memory _ipfsHash) public onlyRegisteredPatient {
        patients[msg.sender].medicalReports.push(_ipfsHash);
        emit ReportUploaded(msg.sender, _ipfsHash);
    }

    // Doctor function to add diagnosis and reward patients
    function addDiagnosis(address _patientAddress, string memory _diagnosis) public onlyApprovedDoctor {
        require(patients[_patientAddress].isRegistered, "Patient not registered.");
        patients[_patientAddress].medicalHistory = string(abi.encodePacked(patients[_patientAddress].medicalHistory, "; ", _diagnosis));
        
        // Reward patient with tokens for sharing their data
        patients[_patientAddress].tokenBalance += tokenReward;
        emit RewardTokensIssued(_patientAddress, tokenReward);
    }

    // Function for viewing medical history and reports (Admin, doctor, or patient)
    function viewMedicalHistory(address _patientAddress) public view returns (string memory, string[] memory) {
        require(
            msg.sender == admin || msg.sender == _patientAddress || doctors[msg.sender].isApproved,
            "Not authorized to view medical history."
        );
        return (patients[_patientAddress].medicalHistory, patients[_patientAddress].medicalReports);
    }

    // Patient files an insurance claim
    function fileInsuranceClaim(uint _claimAmount) public onlyRegisteredPatient {
        claims[claimIndex] = InsuranceClaim(msg.sender, admin, _claimAmount, false, false);
        emit InsuranceClaimFiled(claimIndex, msg.sender, _claimAmount);
        claimIndex++;
    }

    // Admin approves an insurance claim
    function approveInsuranceClaim(uint _claimId) public onlyAdmin {
        InsuranceClaim storage claim = claims[_claimId];
        require(!claim.isApproved, "Claim already approved.");
        claim.isApproved = true;
        emit InsuranceClaimApproved(_claimId);
    }

    // Additional feature: Rating doctors
    function rateDoctor(address _doctorAddress, uint _rating) public onlyRegisteredPatient {
        require(doctors[_doctorAddress].isApproved, "Doctor not approved.");
        require(_rating > 0 && _rating <= 5, "Rating should be between 1 and 5.");
        
        Doctor storage doctor = doctors[_doctorAddress];
        doctor.totalRatings += _rating;
        doctor.numberOfRatings++;
        doctor.rating = doctor.totalRatings / doctor.numberOfRatings;
    }

    // Additional feature: Patient referral rewards
    function referPatient(address _newPatientAddress) public onlyRegisteredPatient {
        require(!patients[_newPatientAddress].isRegistered, "Patient already registered.");
        patients[msg.sender].tokenBalance += 50;  // Referral reward
    }
}
