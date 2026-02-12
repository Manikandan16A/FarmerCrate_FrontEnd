
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../Customer/customerhomepage.dart';
import '../Farmer/homepage.dart';
import '../Transpoter/transporter_dashboard.dart';
import '../utils/cloudinary_upload.dart';
import '../utils/snackbar_utils.dart';
import 'Signin.dart';
import 'google_profile_completion.dart';


class SignUpPage extends StatefulWidget {
const SignUpPage({super.key});
@override
_SignUpPageState createState() => _SignUpPageState();
}

class _SignUpPageState extends State<SignUpPage> with TickerProviderStateMixin {
final _formKey = GlobalKey<FormState>();
final _usernameController = TextEditingController();
final _emailController = TextEditingController();
final _passwordController = TextEditingController();
final _confirmPasswordController = TextEditingController();
final _phoneController = TextEditingController();
final _addressController = TextEditingController();
final _zoneController = TextEditingController();
final _districtController = TextEditingController();
final _stateController = TextEditingController();
final _accountNumberController = TextEditingController();
final _ifscCodeController = TextEditingController();
final _globalFarmerIdController = TextEditingController();


final _ageController = TextEditingController();
final _aadharNumberController = TextEditingController();
final _panNumberController = TextEditingController();
final _voterIdNumberController = TextEditingController();
final _licenseNumberController = TextEditingController();

bool _isPasswordVisible = false;
bool _isConfirmPasswordVisible = false;
bool _isLoading = false;
String? _selectedRole = 'Farmer';
File? _selectedImage;
File? _selectedAadharFile;
File? _selectedPanFile;
File? _selectedVoterIdFile;
File? _selectedLicenseFile;
final ImagePicker _picker = ImagePicker();
final GoogleSignIn _googleSignIn = GoogleSignIn(
scopes: ['email', 'profile'],
serverClientId: '850075546970-ajmrvfu7lkmvhbogrdk94jt43qv92dnd.apps.googleusercontent.com',
);

late AnimationController _animationController;
late Animation<double> _fadeAnimation;
late Animation<Offset> _slideAnimation;

final List<String> _roles = ['Farmer', 'Customer', 'Transport'];
final List<String> _states = [
'Andhra Pradesh',
'Arunachal Pradesh',
'Assam',
'Bihar',
'Chhattisgarh',
'Goa',
'Gujarat',
'Haryana',
'Himachal Pradesh',
'Jharkhand',
'Karnataka',
'Kerala',
'Madhya Pradesh',
'Maharashtra',
'Manipur',
'Meghalaya',
'Mizoram',
'Nagaland',
'Odisha',
'Punjab',
'Rajasthan',
'Sikkim',
'Tamil Nadu',
'Telangana',
'Tripura',
'Uttar Pradesh',
'Uttarakhand',
'West Bengal',
'Andaman and Nicobar Islands',
'Chandigarh',
'Dadra and Nagar Haveli and Daman and Diu',
'Delhi',
'Jammu and Kashmir',
'Ladakh',
'Lakshadweep',
'Puducherry',
];

final Map<String, List<String>> _stateDistricts = {
'Andhra Pradesh': [
'Anantapur', 'Chittoor', 'East Godavari', 'Guntur', 'Krishna', 'Kurnool', 'Prakasam', 'Srikakulam', 'Sri Potti Sriramulu Nellore', 'Visakhapatnam', 'Vizianagaram', 'West Godavari', 'YSR Kadapa'
],
'Arunachal Pradesh': [
'Anjaw', 'Changlang', 'Dibang Valley', 'East Kameng', 'East Siang', 'Kamle', 'Kra Daadi', 'Kurung Kumey', 'Lepa Rada', 'Lohit', 'Longding', 'Lower Dibang Valley', 'Lower Siang', 'Lower Subansiri', 'Namsai', 'Pakke Kessang', 'Papum Pare', 'Shi Yomi', 'Siang', 'Tawang', 'Tirap', 'Upper Siang', 'Upper Subansiri', 'West Kameng', 'West Siang'
],
'Assam': [
'Baksa', 'Barpeta', 'Biswanath', 'Bongaigaon', 'Cachar', 'Charaideo', 'Chirang', 'Darrang', 'Dhemaji', 'Dhubri', 'Dibrugarh', 'Dima Hasao', 'Goalpara', 'Golaghat', 'Hailakandi', 'Hojai', 'Jorhat', 'Kamrup', 'Kamrup Metropolitan', 'Karbi Anglong', 'Karimganj', 'Kokrajhar', 'Lakhimpur', 'Majuli', 'Morigaon', 'Nagaon', 'Nalbari', 'Sivasagar', 'Sonitpur', 'South Salmara-Mankachar', 'Tinsukia', 'Udalguri', 'West Karbi Anglong'
],
'Bihar': [
'Araria', 'Arwal', 'Aurangabad', 'Banka', 'Begusarai', 'Bhagalpur', 'Bhojpur', 'Buxar', 'Darbhanga', 'East Champaran', 'Gaya', 'Gopalganj', 'Jamui', 'Jehanabad', 'Kaimur', 'Katihar', 'Khagaria', 'Kishanganj', 'Lakhisarai', 'Madhepura', 'Madhubani', 'Munger', 'Muzaffarpur', 'Nalanda', 'Nawada', 'Patna', 'Purnia', 'Rohtas', 'Saharsa', 'Samastipur', 'Saran', 'Sheikhpura', 'Sheohar', 'Sitamarhi', 'Siwan', 'Supaul', 'Vaishali', 'West Champaran'
],
'Chhattisgarh': [
'Balod', 'Baloda Bazar', 'Balrampur', 'Bastar', 'Bemetara', 'Bijapur', 'Bilaspur', 'Dantewada', 'Dhamtari', 'Durg', 'Gariaband', 'Gaurela-Pendra-Marwahi', 'Janjgir-Champa', 'Jashpur', 'Kabirdham', 'Kanker', 'Kondagaon', 'Korba', 'Koriya', 'Mahasamund', 'Mungeli', 'Narayanpur', 'Raigarh', 'Raipur', 'Rajnandgaon', 'Sukma', 'Surajpur', 'Surguja'
],
'Goa': [
'North Goa', 'South Goa'
],
'Gujarat': [
'Ahmedabad', 'Amreli', 'Anand', 'Aravalli', 'Banaskantha', 'Bharuch', 'Bhavnagar', 'Botad', 'Chhota Udaipur', 'Dahod', 'Dang', 'Devbhoomi Dwarka', 'Gandhinagar', 'Gir Somnath', 'Jamnagar', 'Junagadh', 'Kheda', 'Kutch', 'Mahisagar', 'Mehsana', 'Morbi', 'Narmada', 'Navsari', 'Panchmahal', 'Patan', 'Porbandar', 'Rajkot', 'Sabarkantha', 'Surat', 'Surendranagar', 'Tapi', 'Vadodara', 'Valsad'
],
'Haryana': [
'Ambala', 'Bhiwani', 'Charkhi Dadri', 'Faridabad', 'Fatehabad', 'Gurugram', 'Hisar', 'Jhajjar', 'Jind', 'Kaithal', 'Karnal', 'Kurukshetra', 'Mahendragarh', 'Nuh', 'Palwal', 'Panchkula', 'Panipat', 'Rewari', 'Rohtak', 'Sirsa', 'Sonipat', 'Yamunanagar'
],
'Himachal Pradesh': [
'Bilaspur', 'Chamba', 'Hamirpur', 'Kangra', 'Kinnaur', 'Kullu', 'Lahaul and Spiti', 'Mandi', 'Shimla', 'Sirmaur', 'Solan', 'Una'
],
'Jharkhand': [
'Bokaro', 'Chatra', 'Deoghar', 'Dhanbad', 'Dumka', 'East Singhbhum', 'Garhwa', 'Giridih', 'Godda', 'Gumla', 'Hazaribagh', 'Jamtara', 'Khunti', 'Koderma', 'Latehar', 'Lohardaga', 'Pakur', 'Palamu', 'Ramgarh', 'Ranchi', 'Sahebganj', 'Seraikela Kharsawan', 'Simdega', 'West Singhbhum'
],
'Karnataka': [
'Bagalkot', 'Ballari', 'Belagavi', 'Bengaluru Rural', 'Bengaluru Urban', 'Bidar', 'Chamarajanagar', 'Chikballapur', 'Chikkamagaluru', 'Chitradurga', 'Dakshina Kannada', 'Davanagere', 'Dharwad', 'Gadag', 'Hassan', 'Haveri', 'Kalaburagi', 'Kodagu', 'Kolar', 'Koppal', 'Mandya', 'Mysuru', 'Raichur', 'Ramanagara', 'Shivamogga', 'Tumakuru', 'Udupi', 'Uttara Kannada', 'Vijayapura', 'Yadgir'
],
'Kerala': [
'Alappuzha', 'Ernakulam', 'Idukki', 'Kannur', 'Kasaragod', 'Kollam', 'Kottayam', 'Kozhikode', 'Malappuram', 'Palakkad', 'Pathanamthitta', 'Thiruvananthapuram', 'Thrissur', 'Wayanad'
],
'Madhya Pradesh': [
'Agar Malwa', 'Alirajpur', 'Anuppur', 'Ashoknagar', 'Balaghat', 'Barwani', 'Betul', 'Bhind', 'Bhopal', 'Burhanpur', 'Chhatarpur', 'Chhindwara', 'Damoh', 'Datia', 'Dewas', 'Dhar', 'Dindori', 'Guna', 'Gwalior', 'Harda', 'Hoshangabad', 'Indore', 'Jabalpur', 'Jhabua', 'Katni', 'Khandwa', 'Khargone', 'Mandla', 'Mandsaur', 'Morena', 'Narsinghpur', 'Neemuch', 'Niwari', 'Panna', 'Raisen', 'Rajgarh', 'Ratlam', 'Rewa', 'Sagar', 'Satna', 'Sehore', 'Seoni', 'Shahdol', 'Shajapur', 'Sheopur', 'Shivpuri', 'Sidhi', 'Singrauli', 'Tikamgarh', 'Ujjain', 'Umaria', 'Vidisha'
],
'Maharashtra': [
'Ahmednagar', 'Akola', 'Amravati', 'Aurangabad', 'Beed', 'Bhandara', 'Buldhana', 'Chandrapur', 'Dhule', 'Gadchiroli', 'Gondia', 'Hingoli', 'Jalgaon', 'Jalna', 'Kolhapur', 'Latur', 'Mumbai City', 'Mumbai Suburban', 'Nagpur', 'Nanded', 'Nandurbar', 'Nashik', 'Osmanabad', 'Palghar', 'Parbhani', 'Pune', 'Raigad', 'Ratnagiri', 'Sangli', 'Satara', 'Sindhudurg', 'Solapur', 'Thane', 'Wardha', 'Washim', 'Yavatmal'
],
'Manipur': [
'Bishnupur', 'Chandel', 'Churachandpur', 'Imphal East', 'Imphal West', 'Jiribam', 'Kakching', 'Kamjong', 'Kangpokpi', 'Noney', 'Pherzawl', 'Senapati', 'Tamenglong', 'Tengnoupal', 'Thoubal', 'Ukhrul'
],
'Meghalaya': [
'East Garo Hills', 'East Jaintia Hills', 'East Khasi Hills', 'North Garo Hills', 'Ri Bhoi', 'South Garo Hills', 'South West Garo Hills', 'South West Khasi Hills', 'West Garo Hills', 'West Jaintia Hills', 'West Khasi Hills'
],
'Mizoram': [
'Aizawl', 'Champhai', 'Hnahthial', 'Khawzawl', 'Kolasib', 'Lawngtlai', 'Lunglei', 'Mamit', 'Saiha', 'Saitual', 'Serchhip'
],
'Nagaland': [
'Dimapur', 'Kiphire', 'Kohima', 'Longleng', 'Mokokchung', 'Mon', 'Noklak', 'Peren', 'Phek', 'Tuensang', 'Wokha', 'Zunheboto'
],
'Odisha': [
'Angul', 'Balangir', 'Balasore', 'Bargarh', 'Bhadrak', 'Boudh', 'Cuttack', 'Deogarh', 'Dhenkanal', 'Gajapati', 'Ganjam', 'Jagatsinghpur', 'Jajpur', 'Jharsuguda', 'Kalahandi', 'Kandhamal', 'Kendrapara', 'Kendujhar', 'Khordha', 'Koraput', 'Malkangiri', 'Mayurbhanj', 'Nabarangpur', 'Nayagarh', 'Nuapada', 'Puri', 'Rayagada', 'Sambalpur', 'Sonepur', 'Sundargarh'
],
'Punjab': [
'Amritsar', 'Barnala', 'Bathinda', 'Faridkot', 'Fatehgarh Sahib', 'Fazilka', 'Ferozepur', 'Gurdaspur', 'Hoshiarpur', 'Jalandhar', 'Kapurthala', 'Ludhiana', 'Malerkotla', 'Mansa', 'Moga', 'Mohali', 'Muktsar', 'Pathankot', 'Patiala', 'Rupnagar', 'Sangrur', 'SAS Nagar', 'SBS Nagar', 'Sri Muktsar Sahib', 'Tarn Taran'
],
'Rajasthan': [
'Ajmer', 'Alwar', 'Banswara', 'Baran', 'Barmer', 'Bharatpur', 'Bhilwara', 'Bikaner', 'Bundi', 'Chittorgarh', 'Churu', 'Dausa', 'Dholpur', 'Dungarpur', 'Ganganagar', 'Hanumangarh', 'Jaipur', 'Jaisalmer', 'Jalore', 'Jhalawar', 'Jhunjhunu', 'Jodhpur', 'Karauli', 'Kota', 'Nagaur', 'Pali', 'Pratapgarh', 'Rajsamand', 'Sawai Madhopur', 'Sikar', 'Sirohi', 'Tonk', 'Udaipur'
],
'Sikkim': [
'East Sikkim', 'North Sikkim', 'South Sikkim', 'West Sikkim', 'Pakyong', 'Soreng'
],
'Tamil Nadu': [
'Ariyalur', 'Chengalpattu', 'Chennai', 'Coimbatore', 'Cuddalore', 'Dharmapuri', 'Dindigul', 'Erode', 'Kallakurichi', 'Kanchipuram', 'Kanyakumari', 'Karur', 'Krishnagiri', 'Madurai', 'Mayiladuthurai', 'Nagapattinam', 'Namakkal', 'Nilgiris', 'Perambalur', 'Pudukkottai', 'Ramanathapuram', 'Ranipet', 'Salem', 'Sivaganga', 'Tenkasi', 'Thanjavur', 'Theni', 'Thoothukudi', 'Tiruchirappalli', 'Tirunelveli', 'Tirupathur', 'Tiruppur', 'Tiruvallur', 'Tiruvannamalai', 'Tiruvarur', 'Vellore', 'Viluppuram', 'Virudhunagar'
],
'Telangana': [
'Adilabad', 'Bhadradri Kothagudem', 'Hyderabad', 'Jagtial', 'Jangaon', 'Jayashankar Bhupalapally', 'Jogulamba Gadwal', 'Kamareddy', 'Karimnagar', 'Khammam', 'Komaram Bheem', 'Mahabubabad', 'Mahabubnagar', 'Mancherial', 'Medak', 'Medchal–Malkajgiri', 'Mulugu', 'Nagarkurnool', 'Nalgonda', 'Narayanpet', 'Nirmal', 'Nizamabad', 'Peddapalli', 'Rajanna Sircilla', 'Ranga Reddy', 'Sangareddy', 'Siddipet', 'Suryapet', 'Vikarabad', 'Wanaparthy', 'Warangal Rural', 'Warangal Urban', 'Yadadri Bhuvanagiri'
],
'Tripura': [
'Dhalai', 'Gomati', 'Khowai', 'North Tripura', 'Sepahijala', 'South Tripura', 'Unakoti', 'West Tripura'
],
'Uttar Pradesh': [
'Agra', 'Aligarh', 'Ambedkar Nagar', 'Amethi', 'Amroha', 'Auraiya', 'Ayodhya', 'Azamgarh', 'Baghpat', 'Bahraich', 'Ballia', 'Balrampur', 'Banda', 'Barabanki', 'Bareilly', 'Basti', 'Bhadohi', 'Bijnor', 'Budaun', 'Bulandshahr', 'Chandauli', 'Chitrakoot', 'Deoria', 'Etah', 'Etawah', 'Farrukhabad', 'Fatehpur', 'Firozabad', 'Gautam Buddha Nagar', 'Ghaziabad', 'Ghazipur', 'Gonda', 'Gorakhpur', 'Hamirpur', 'Hapur', 'Hardoi', 'Hathras', 'Jalaun', 'Jaunpur', 'Jhansi', 'Kannauj', 'Kanpur Dehat', 'Kanpur Nagar', 'Kasganj', 'Kaushambi', 'Kheri', 'Kushinagar', 'Lalitpur', 'Lucknow', 'Maharajganj', 'Mahoba', 'Mainpuri', 'Mathura', 'Mau', 'Meerut', 'Mirzapur', 'Moradabad', 'Muzaffarnagar', 'Pilibhit', 'Pratapgarh', 'Prayagraj', 'Raebareli', 'Rampur', 'Saharanpur', 'Sambhal', 'Sant Kabir Nagar', 'Shahjahanpur', 'Shamli', 'Shravasti', 'Siddharthnagar', 'Sitapur', 'Sonbhadra', 'Sultanpur', 'Unnao', 'Varanasi'
],
'Uttarakhand': [
'Almora', 'Bageshwar', 'Chamoli', 'Champawat', 'Dehradun', 'Haridwar', 'Nainital', 'Pauri Garhwal', 'Pithoragarh', 'Rudraprayag', 'Tehri Garhwal', 'Udham Singh Nagar', 'Uttarkashi'
],
'West Bengal': [
'Alipurduar', 'Bankura', 'Birbhum', 'Cooch Behar', 'Dakshin Dinajpur', 'Darjeeling', 'Hooghly', 'Howrah', 'Jalpaiguri', 'Jhargram', 'Kalimpong', 'Kolkata', 'Malda', 'Murshidabad', 'Nadia', 'North 24 Parganas', 'Paschim Bardhaman', 'Paschim Medinipur', 'Purba Bardhaman', 'Purba Medinipur', 'Purulia', 'South 24 Parganas', 'Uttar Dinajpur'
],
'Andaman and Nicobar Islands': [
'Nicobar', 'North and Middle Andaman', 'South Andaman'
],
'Chandigarh': [
'Chandigarh'
],
'Dadra and Nagar Haveli and Daman and Diu': [
'Dadra and Nagar Haveli', 'Daman', 'Diu'
],
'Delhi': [
'Central Delhi', 'East Delhi', 'New Delhi', 'North Delhi', 'North East Delhi', 'North West Delhi', 'Shahdara', 'South Delhi', 'South East Delhi', 'South West Delhi', 'West Delhi'
],
'Jammu and Kashmir': [
'Anantnag', 'Bandipora', 'Baramulla', 'Budgam', 'Doda', 'Ganderbal', 'Jammu', 'Kathua', 'Kishtwar', 'Kulgam', 'Kupwara', 'Poonch', 'Pulwama', 'Rajouri', 'Ramban', 'Reasi', 'Samba', 'Shopian', 'Srinagar', 'Udhampur'
],
'Ladakh': [
'Kargil', 'Leh'
],
'Lakshadweep': [
'Agatti', 'Amini', 'Andrott', 'Bithra', 'Chetlat', 'Kadmat', 'Kalpeni', 'Kavaratti', 'Kilthan', 'Minicoy'
],
'Puducherry': [
'Karaikal', 'Mahe', 'Puducherry', 'Yanam'
],
};

@override
void initState() {
super.initState();
_animationController = AnimationController(
duration: const Duration(milliseconds: 1500),
vsync: this,
);

_fadeAnimation = Tween<double>(
begin: 0.0,
end: 1.0,
).animate(CurvedAnimation(
parent: _animationController,
curve: Curves.easeInOut,
));

_slideAnimation = Tween<Offset>(
begin: const Offset(0, 0.5),
end: Offset.zero,
).animate(CurvedAnimation(
parent: _animationController,
curve: Curves.easeOutBack,
));

_animationController.forward();

// Add listener to state controller to clear district when state changes
_stateController.addListener(() {
// If the state changes, clear the district and update UI
if ((_stateController.text.isEmpty && _districtController.text.isNotEmpty) ||
(_stateController.text.isNotEmpty && !(_stateDistricts[_stateController.text] ?? []).contains(_districtController.text))) {
_districtController.clear();
setState(() {});
}
});
}

@override
void dispose() {
_animationController.dispose();
_usernameController.dispose();
_emailController.dispose();
_passwordController.dispose();
_confirmPasswordController.dispose();
_phoneController.dispose();
_addressController.dispose();
_zoneController.dispose();
_districtController.dispose();
_stateController.dispose();
_accountNumberController.dispose();
_ifscCodeController.dispose();
_globalFarmerIdController.dispose();
_ageController.dispose();
_aadharNumberController.dispose();
_panNumberController.dispose();
_voterIdNumberController.dispose();
_licenseNumberController.dispose();
super.dispose();
}

Future<void> _pickImage() async {
try {
final ImageSource? source = await showModalBottomSheet<ImageSource>(
context: context,
shape: const RoundedRectangleBorder(
borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
),
builder: (BuildContext context) {
return Container(
padding: const EdgeInsets.all(20),
child: Column(
mainAxisSize: MainAxisSize.min,
children: [
Container(
width: 40,
height: 4,
margin: const EdgeInsets.only(bottom: 20),
decoration: BoxDecoration(
color: Colors.grey[300],
borderRadius: BorderRadius.circular(2),
),
),
const Text(
'Select Image Source',
style: TextStyle(
fontSize: 18,
fontWeight: FontWeight.bold,
color: Color(0xFF2E7D32),
),
),
const SizedBox(height: 20),
ListTile(
leading: Container(
padding: const EdgeInsets.all(10),
decoration: BoxDecoration(
color: const Color(0xFF4CAF50).withValues(alpha: 0.1),
shape: BoxShape.circle,
),
child: const Icon(Icons.camera_alt, color: Color(0xFF4CAF50)),
),
title: const Text('Camera'),
subtitle: const Text('Take a new photo'),
onTap: () => Navigator.pop(context, ImageSource.camera),
),
const Divider(),
ListTile(
leading: Container(
padding: const EdgeInsets.all(10),
decoration: BoxDecoration(
color: const Color(0xFF4CAF50).withValues(alpha: 0.1),
shape: BoxShape.circle,
),
child: const Icon(Icons.photo_library, color: Color(0xFF4CAF50)),
),
title: const Text('Gallery'),
subtitle: const Text('Choose from gallery'),
onTap: () => Navigator.pop(context, ImageSource.gallery),
),
const Divider(),
ListTile(
leading: Container(
padding: const EdgeInsets.all(10),
decoration: BoxDecoration(
color: Colors.grey[200],
shape: BoxShape.circle,
),
child: const Icon(Icons.close, color: Colors.grey),
),
title: const Text('Cancel'),
subtitle: const Text('Go back'),
onTap: () => Navigator.pop(context),
),
const SizedBox(height: 10),
],
),
);
},
);

if (source != null) {
final XFile? image = await _picker.pickImage(source: source);
if (image != null) {
setState(() {
_selectedImage = File(image.path);
});
}
}
} catch (e) {
SnackBarUtils.showError(context, 'Error picking image: $e');
}
}

Future<void> _pickDocument(String documentType) async {
try {
final ImageSource? source = await showModalBottomSheet<ImageSource>(
context: context,
shape: const RoundedRectangleBorder(
borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
),
builder: (BuildContext context) {
return Container(
padding: const EdgeInsets.all(20),
child: Column(
mainAxisSize: MainAxisSize.min,
children: [
Container(
width: 40,
height: 4,
margin: const EdgeInsets.only(bottom: 20),
decoration: BoxDecoration(
color: Colors.grey[300],
borderRadius: BorderRadius.circular(2),
),
),
const Text(
'Select Document Source',
style: TextStyle(
fontSize: 18,
fontWeight: FontWeight.bold,
color: Color(0xFF2E7D32),
),
),
const SizedBox(height: 20),
ListTile(
leading: Container(
padding: const EdgeInsets.all(10),
decoration: BoxDecoration(
color: const Color(0xFF4CAF50).withValues(alpha: 0.1),
shape: BoxShape.circle,
),
child: const Icon(Icons.camera_alt, color: Color(0xFF4CAF50)),
),
title: const Text('Camera'),
subtitle: const Text('Take a new photo'),
onTap: () => Navigator.pop(context, ImageSource.camera),
),
const Divider(),
ListTile(
leading: Container(
padding: const EdgeInsets.all(10),
decoration: BoxDecoration(
color: const Color(0xFF4CAF50).withValues(alpha: 0.1),
shape: BoxShape.circle,
),
child: const Icon(Icons.photo_library, color: Color(0xFF4CAF50)),
),
title: const Text('Gallery'),
subtitle: const Text('Choose from gallery'),
onTap: () => Navigator.pop(context, ImageSource.gallery),
),
const Divider(),
ListTile(
leading: Container(
padding: const EdgeInsets.all(10),
decoration: BoxDecoration(
color: Colors.grey[200],
shape: BoxShape.circle,
),
child: const Icon(Icons.close, color: Colors.grey),
),
title: const Text('Cancel'),
subtitle: const Text('Go back'),
onTap: () => Navigator.pop(context),
),
const SizedBox(height: 10),
],
),
);
},
);

if (source != null) {
final XFile? file = await _picker.pickImage(source: source);
if (file != null) {
setState(() {
switch (documentType) {
case 'aadhar':
_selectedAadharFile = File(file.path);
break;
case 'pan':
_selectedPanFile = File(file.path);
break;
case 'voter':
_selectedVoterIdFile = File(file.path);
break;
case 'license':
_selectedLicenseFile = File(file.path);
break;
}
});
}
}
} catch (e) {
SnackBarUtils.showError(context, 'Error picking document: $e');
}
}

String _getImageLabel() {
switch (_selectedRole) {
case 'Farmer':
return 'Passport Image';
case 'Customer':
return 'Profile Image';
case 'Transport':
return 'Passport Size Image';
default:
return 'Profile Image';
}
}

String _getImagePlaceholderText() {
switch (_selectedRole) {
case 'Farmer':
return 'Tap to select passport image';
case 'Customer':
return 'Tap to select profile image';
case 'Transport':
return 'Tap to select Profile image';
default:
return 'Tap to select image';
}
}

// Temporary debug function to test API endpoint
Future<void> _testAPIEndpoint() async {
try {
// Try a simple GET request to check if the API is reachable
final testResponse = await http.get(
Uri.parse('https://farmercrate.onrender.com/api/products'),
).timeout(const Duration(seconds: 10));

print('API Test Response: ${testResponse.statusCode}');
print('API Test Body Length: ${testResponse.body.length}');

if (testResponse.statusCode == 200) {
print('API is reachable and responding');
} else {
print('API returned status: ${testResponse.statusCode}');
}
} catch (e) {
print('API Test Error: $e');
}
}

void _showSuccessDialog(String title, String message, {required VoidCallback onOk}) {
showDialog(
context: context,
barrierDismissible: false,
builder: (BuildContext context) {
return Dialog(
shape: RoundedRectangleBorder(
borderRadius: BorderRadius.circular(20),
),
child: Container(
padding: const EdgeInsets.all(24),
decoration: BoxDecoration(
color: Colors.white,
borderRadius: BorderRadius.circular(20),
border: Border.all(color: const Color(0xFF4CAF50), width: 2),
),
child: Column(
mainAxisSize: MainAxisSize.min,
children: [
// Success icon with green background
Container(
width: 80,
height: 80,
decoration: const BoxDecoration(
color: Color(0xFF4CAF50),
shape: BoxShape.circle,
),
child: const Icon(
Icons.check,
color: Colors.white,
size: 50,
),
),
const SizedBox(height: 20),
// Title
Text(
title,
style: const TextStyle(
fontSize: 24,
fontWeight: FontWeight.bold,
color: Color(0xFF2E7D32),
),
textAlign: TextAlign.center,
),
const SizedBox(height: 16),
// Message
Text(
message,
style: const TextStyle(
fontSize: 16,
color: Color(0xFF424242),
height: 1.4,
),
textAlign: TextAlign.center,
),
const SizedBox(height: 24),
// OK Button
SizedBox(
width: double.infinity,
child: ElevatedButton(
onPressed: () {
Navigator.of(context).pop();
onOk();
},
style: ElevatedButton.styleFrom(
backgroundColor: const Color(0xFF4CAF50),
foregroundColor: Colors.white,
padding: const EdgeInsets.symmetric(vertical: 16),
shape: RoundedRectangleBorder(
borderRadius: BorderRadius.circular(12),
),
elevation: 2,
),
child: const Text(
'OK',
style: TextStyle(
fontSize: 16,
fontWeight: FontWeight.w600,
),
),
),
),
],
),
),
);
},
);
}

void _handleSignUp() async {
if (_formKey.currentState!.validate()) {
if (_selectedImage == null) {
String imageType = _selectedRole == 'Farmer'
? 'passport image'
    : _selectedRole == 'Transport'
? 'profile image'
    : 'profile image';

SnackBarUtils.showError(context, 'Please select a $imageType');
return;
}

// Check transporter-specific document requirements
if (_selectedRole == 'Transport') {
if (_selectedAadharFile == null || _selectedPanFile == null ||
_selectedVoterIdFile == null || _selectedLicenseFile == null) {
SnackBarUtils.showError(context, 'Please upload all required documents (Aadhar, PAN, Voter ID, License)');
return;
}
}

setState(() {
_isLoading = true;
});

try {
// 1. Upload image to Cloudinary with retry mechanism
String? imageUrl;
int retryCount = 0;
const maxRetries = 2;

while (imageUrl == null && retryCount < maxRetries) {
if (retryCount > 0) {
// Show retry message
SnackBarUtils.showWarning(context, 'Retrying image upload... ($retryCount/$maxRetries)');
}

imageUrl = await CloudinaryUploader.uploadImage(_selectedImage!);
retryCount++;

if (imageUrl == null && retryCount < maxRetries) {
// Wait a bit before retrying
await Future.delayed(const Duration(seconds: 1));
}
}

// Upload transporter documents if role is Transport
String? aadharUrl, panUrl, voterIdUrl, licenseUrl;
if (_selectedRole == 'Transport') {
// Upload Aadhar document
aadharUrl = await CloudinaryUploader.uploadImage(_selectedAadharFile!);
if (aadharUrl == null) {
setState(() { _isLoading = false; });
SnackBarUtils.showError(context, 'Failed to upload Aadhar document. Please try again.');
return;
}

// Upload PAN document
panUrl = await CloudinaryUploader.uploadImage(_selectedPanFile!);
if (panUrl == null) {
setState(() { _isLoading = false; });
SnackBarUtils.showError(context, 'Failed to upload PAN document. Please try again.');
return;
}

// Upload Voter ID document
voterIdUrl = await CloudinaryUploader.uploadImage(_selectedVoterIdFile!);
if (voterIdUrl == null) {
setState(() { _isLoading = false; });
SnackBarUtils.showError(context, 'Failed to upload Voter ID document. Please try again.');
return;
}

// Upload License document
licenseUrl = await CloudinaryUploader.uploadImage(_selectedLicenseFile!);
if (licenseUrl == null) {
setState(() { _isLoading = false; });
SnackBarUtils.showError(context, 'Failed to upload License document. Please try again.');
return;
}
}

// Handle null return from Cloudinary upload after all retries
if (imageUrl == null) {
setState(() { _isLoading = false; });
SnackBarUtils.showError(context, 'Image upload failed after $maxRetries attempts. Please check your internet connection and try again.');
return;
}

// Debug: Print image upload success
print('Image uploaded successfully: $imageUrl');

// 2. Proceed with registration, including imageUrl
final backendRole = _selectedRole!.toLowerCase();
// Convert 'transport' to 'transporter' to match API
final apiRole = backendRole == 'transport' ? 'transporter' : backendRole;

// Prepare request body exactly as API expects
final String generatedGlobalId = 'GOV${DateTime.now().millisecondsSinceEpoch}';
Map<String, dynamic> requestBody = {
'role': apiRole,
'name': _usernameController.text.trim(),
'email': _emailController.text.trim(),
'password': _passwordController.text,
// API expects mobileNumber for transporter, mobile_number for others
apiRole == 'transporter' ? 'mobileNumber' : 'mobile_number': _phoneController.text.trim(),
'address': _addressController.text.trim(),
'zone': _zoneController.text.trim(),
'state': _stateController.text.trim(),
'district': _districtController.text.trim(),
'image_url': imageUrl,
};

// Validate required fields
if (_usernameController.text.trim().isEmpty ||
_emailController.text.trim().isEmpty ||
_passwordController.text.isEmpty ||
_phoneController.text.trim().isEmpty ||
_addressController.text.trim().isEmpty ||
_zoneController.text.trim().isEmpty ||
_districtController.text.trim().isEmpty ||
_stateController.text.trim().isEmpty ||
_ageController.text.trim().isEmpty) {
SnackBarUtils.showError(context, 'Please fill in all required fields');
return;
}

// Validate transporter-specific fields
if (apiRole == 'transporter') {
if (_aadharNumberController.text.trim().isEmpty ||
_panNumberController.text.trim().isEmpty ||
_voterIdNumberController.text.trim().isEmpty ||
_licenseNumberController.text.trim().isEmpty ||
_accountNumberController.text.trim().isEmpty ||
_ifscCodeController.text.trim().isEmpty) {
SnackBarUtils.showError(context, 'Please fill in all transporter-specific fields');
return;
}
}

// Test API endpoint first (temporary debug)
await _testAPIEndpoint();

// Add age for all roles
requestBody['age'] = int.tryParse(_ageController.text.trim()) ?? 25;

// Add role-specific fields
if (apiRole == 'farmer') {
// Add farmer-specific required fields per API spec
requestBody['account_number'] = _accountNumberController.text.trim();
requestBody['ifsc_code'] = _ifscCodeController.text.trim();
final enteredGlobalId = _globalFarmerIdController.text.trim();
requestBody['global_farmer_id'] = enteredGlobalId.isEmpty ? generatedGlobalId : enteredGlobalId;
} else if (apiRole == 'transporter') {
// Add transporter-specific required fields
requestBody['aadhar_url'] = aadharUrl;
requestBody['pan_url'] = panUrl;
requestBody['voter_id_url'] = voterIdUrl;
requestBody['license_url'] = licenseUrl;
requestBody['aadhar_number'] = _aadharNumberController.text.trim();
requestBody['account_number'] = _accountNumberController.text.trim();
requestBody['ifsc_code'] = _ifscCodeController.text.trim();
requestBody['pan_number'] = _panNumberController.text.trim();
requestBody['voter_id_number'] = _voterIdNumberController.text.trim();
requestBody['license_number'] = _licenseNumberController.text.trim();
}

// Debug: Print request details AFTER role-specific fields are added
print('API Role: $apiRole');
print('Request Body: ${jsonEncode(requestBody)}');

// Try the request with retry logic
http.Response? response;
int requestRetryCount = 0;
const maxRequestRetries = 3;

while (requestRetryCount < maxRequestRetries) {
try {
response = await http.post(
Uri.parse('https://farmercrate.onrender.com/api/auth/register'),
headers: {
'Content-Type': 'application/json',
'Accept': 'application/json',
},
body: jsonEncode(requestBody),
).timeout(
const Duration(seconds: 30),
onTimeout: () {
throw Exception('Request timeout. Please check your internet connection.');
},
);
break; // Success, exit retry loop
} catch (e) {
requestRetryCount++;
print('Request attempt $requestRetryCount failed: $e');
if (requestRetryCount >= maxRequestRetries) {
rethrow; // Re-throw the last error
}
// Wait before retrying
await Future.delayed(Duration(seconds: requestRetryCount));
}
}

if (response == null) {
throw Exception('Failed to get response after $maxRequestRetries attempts');
}

// Debug: Print response details
print('Response Status Code: ${response.statusCode}');
print('Response Body: ${response.body}');

setState(() {
_isLoading = false;
});

Map<String, dynamic> responseData;
try {
responseData = jsonDecode(response.body);
} catch (e) {
SnackBarUtils.showError(context, 'Error registering user: Invalid server response - $e');
return;
}

if ((response.statusCode == 200 || response.statusCode == 201) &&
(responseData['success'] == true || responseData['success'] == 'true')) {
// Standardized response structure: { success, message, data: { id, name, email, role } }
final data = responseData['data'];
if (data == null) {
SnackBarUtils.showError(context, 'Missing data from server response');
return;
}
final Map<String, dynamic> userData = {
'id': data['id'],
'name': data['name'],
'email': data['email'],
'role': data['role'] ?? apiRole,
};

final prefs = await SharedPreferences.getInstance();
await prefs.setString('jwt_token', 'temp_token_${userData['id']}');
await prefs.setString('username', (userData['name'] ?? '').toString());
await prefs.setString('email', (userData['email'] ?? '').toString());
await prefs.setString('role', (userData['role'] ?? apiRole).toString());
await prefs.setInt('user_id', userData['id'] ?? 0);
await prefs.setInt('customer_id', userData['id'] ?? 0);

String title = 'Account Created!';
String successMessage = '';

if (apiRole == 'farmer') {
successMessage = 'Your account has created successfully. Wait for verification to join our family.';
} else if (apiRole == 'transporter') {
successMessage = 'Your account has created successfully. Wait for verification to join our family.';
} else {
successMessage = 'Your account created successfully.';
}

// Show success dialog
_showSuccessDialog(
title,
successMessage,
onOk: () {
Navigator.pushReplacement(
context,
MaterialPageRoute(
builder: (context) => LoginPage(),
),
);
},
);
} else {
String errorMessage = 'Error registering user (Status: ${response.statusCode})';
if (responseData.isNotEmpty) {
errorMessage = responseData['message']?.toString() ?? errorMessage;

// Handle email uniqueness conflict (409 status)
if (response.statusCode == 409 && responseData['existingRole'] != null) {
final existingRole = responseData['existingRole'];
showDialog(
context: context,
builder: (BuildContext context) {
return AlertDialog(
title: Row(
children: [
Icon(Icons.warning, color: Colors.orange),
SizedBox(width: 8),
Text('Email Already Registered'),
],
),
content: Column(
mainAxisSize: MainAxisSize.min,
children: [
Text(
'This email is already registered as a $existingRole.',
style: TextStyle(fontSize: 16),
),
SizedBox(height: 12),
Text(
'Please use a different email address or sign in with your existing account.',
style: TextStyle(fontSize: 14, color: Colors.grey[600]),
),
],
),
actions: [
TextButton(
onPressed: () => Navigator.pop(context),
child: Text('OK'),
),
TextButton(
onPressed: () {
Navigator.pop(context);
Navigator.pushReplacement(
context,
MaterialPageRoute(builder: (context) => LoginPage()),
);
},
child: Text('Go to Login'),
),
],
);
},
);
return;
}

if (responseData['errors'] != null) {
try {
final errors = responseData['errors'] as List;
final errorMessages = errors
    .map((error) => error['msg']?.toString() ?? '')
    .where((msg) => msg.isNotEmpty)
    .toList();
if (errorMessages.isNotEmpty) {
errorMessage = errorMessages.join(', ');
}
} catch (e) {
print('Error parsing error messages: $e');
}
}
}

print('Registration failed: $errorMessage');
print('Full response: ${response.body}');

SnackBarUtils.showError(context, errorMessage);
}
} catch (error) {
setState(() {
_isLoading = false;
});

String errorMessage = 'Error registering user';
if (error.toString().contains('timeout')) {
errorMessage = 'Request timeout. Please check your internet connection and try again.';
} else if (error.toString().contains('SocketException')) {
errorMessage = 'No internet connection. Please check your network and try again.';
} else if (error.toString().contains('FormatException')) {
errorMessage = 'Invalid response from server. Please try again.';
} else {
errorMessage = 'Error registering: $error';
}

print('Registration error: $error');

SnackBarUtils.showError(context, errorMessage);
}
}
}

Future<void> _handleGoogleSignUp() async {
final String? selectedRole = await showDialog<String>(
context: context,
builder: (context) => AlertDialog(
title: Text('Select Your Role'),
content: Column(
mainAxisSize: MainAxisSize.min,
children: [
ListTile(
leading: Icon(Icons.shopping_cart, color: Color(0xFF4CAF50)),
title: Text('Customer'),
onTap: () => Navigator.pop(context, 'customer'),
),
ListTile(
leading: Icon(Icons.agriculture, color: Color(0xFF4CAF50)),
title: Text('Farmer'),
onTap: () => Navigator.pop(context, 'farmer'),
),
ListTile(
leading: Icon(Icons.local_shipping, color: Color(0xFF4CAF50)),
title: Text('Transporter'),
onTap: () => Navigator.pop(context, 'transporter'),
),
],
),
),
);

if (selectedRole == null) return;

setState(() {
_isLoading = true;
});

try {
await _googleSignIn.signOut();

final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();

if (googleUser == null) {
setState(() {
_isLoading = false;
});
return;
}

final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
final String? idToken = googleAuth.idToken;

if (idToken == null) {
throw Exception('Failed to get ID token');
}

final response = await http.post(
Uri.parse('https://farmercrate.onrender.com/api/auth/google-signin'),
headers: {'Content-Type': 'application/json'},
body: jsonEncode({
'idToken': idToken,
'role': selectedRole,
}),
);

setState(() {
_isLoading = false;
});

if (response.statusCode == 200) {
final data = jsonDecode(response.body);

if (data['token'] != null) {
final token = data['token'];
final user = data['user'];

final prefs = await SharedPreferences.getInstance();
await prefs.setString('jwt_token', token);
await prefs.setString('auth_token', token);
await prefs.setString('role', selectedRole);
await prefs.setInt('user_id', user['id']);
await prefs.setString('username', user['name']);
await prefs.setString('email', user['email']);
await prefs.setBool('is_logged_in', true);

if (selectedRole == 'customer') {
Navigator.pushReplacement(
context,
MaterialPageRoute(builder: (context) => CustomerHomePage(token: token)),
);
} else if (selectedRole == 'transporter') {
Navigator.pushReplacement(
context,
MaterialPageRoute(builder: (context) => TransporterDashboard(token: token)),
);
} else {
Navigator.pushReplacement(
context,
MaterialPageRoute(builder: (context) => FarmersHomePage(token: token)),
);
}
} else {
Navigator.pushReplacement(
context,
MaterialPageRoute(
builder: (context) => GoogleProfileCompletionPage(
email: googleUser.email,
name: googleUser.displayName ?? 'User',
googleId: googleUser.id,
role: selectedRole,
),
),
);
}
} else if (response.statusCode == 400) {
final data = jsonDecode(response.body);
final existingRole = data['existingRole'];

showDialog(
context: context,
builder: (context) => AlertDialog(
title: Row(
children: [
Icon(Icons.error_outline, color: Colors.red, size: 28),
SizedBox(width: 8),
Expanded(child: Text('Email Already Registered')),
],
),
content: Column(
mainAxisSize: MainAxisSize.min,
crossAxisAlignment: CrossAxisAlignment.start,
children: [
Text(
'This email is already registered as a $existingRole.',
style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
),
SizedBox(height: 12),
Text(
'You cannot use the same email for multiple roles.',
style: TextStyle(fontSize: 14, color: Colors.grey[700]),
),
SizedBox(height: 12),
Container(
padding: EdgeInsets.all(12),
decoration: BoxDecoration(
color: Colors.orange[50],
borderRadius: BorderRadius.circular(8),
border: Border.all(color: Colors.orange[200]!),
),
child: Column(
crossAxisAlignment: CrossAxisAlignment.start,
children: [
Text(
'Please:',
style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
),
SizedBox(height: 4),
Text(
'• Select "$existingRole" role to login',
style: TextStyle(fontSize: 13),
),
Text(
'• Or use a different email',
style: TextStyle(fontSize: 13),
),
],
),
),
],
),
actions: [
TextButton(
onPressed: () => Navigator.pop(context),
child: Text('OK', style: TextStyle(color: Color(0xFF4CAF50), fontSize: 16)),
),
],
),
);
} else if (response.statusCode == 403) {
final data = jsonDecode(response.body);
showDialog(
context: context,
builder: (context) => AlertDialog(
title: Row(
children: [
Icon(Icons.pending, color: Colors.orange),
SizedBox(width: 8),
Text('Verification Pending'),
],
),
content: Text(data['message'] ?? 'Your account is pending admin verification. Please wait for approval.'),
actions: [
TextButton(
onPressed: () => Navigator.pop(context),
child: Text('OK'),
),
],
),
);
} else if (response.statusCode == 409) {
final data = jsonDecode(response.body);
final existingRole = data['existingRole'];
final requestedRole = data['requestedRole'];

showDialog(
context: context,
builder: (BuildContext context) {
return AlertDialog(
title: Row(
children: [
Icon(Icons.warning, color: Colors.orange),
SizedBox(width: 8),
Text('Email Already Registered'),
],
),
content: Column(
mainAxisSize: MainAxisSize.min,
children: [
Text(
'This email is already registered as a $existingRole.',
style: TextStyle(fontSize: 16),
),
SizedBox(height: 12),
Text(
'You cannot sign up as a $requestedRole with this email. Please use a different email or sign in with your existing account.',
style: TextStyle(fontSize: 14, color: Colors.grey[600]),
),
],
),
actions: [
TextButton(
onPressed: () => Navigator.pop(context),
child: Text('OK'),
),
TextButton(
onPressed: () {
Navigator.pop(context);
Navigator.pushReplacement(
context,
MaterialPageRoute(builder: (context) => LoginPage()),
);
},
child: Text('Go to Login'),
),
],
);
},
);
} else {
SnackBarUtils.showError(context, 'Google Sign-In failed. Please try again.');
}
} on PlatformException catch (e) {
setState(() {
_isLoading = false;
});
print('Google Sign-In PlatformException: ${e.code}');
print('Error message: ${e.message}');
if (e.code == 'sign_in_failed' || e.code == 'network_error') {
SnackBarUtils.showError(context, 'Google Sign-In not available. Please use regular sign-up.');
} else {
SnackBarUtils.showError(context, 'Error: ${e.message}');
}
} catch (e) {
setState(() {
_isLoading = false;
});
print('Google Sign-In Error: $e');
SnackBarUtils.showError(context, 'Error: $e');
}
}

@override
Widget build(BuildContext context) {
return Scaffold(
body: Container(
decoration: const BoxDecoration(
gradient: LinearGradient(
begin: Alignment.topLeft,
end: Alignment.bottomRight,
colors: [
Color(0xFF2E7D32),
Color(0xFF4CAF50),
Color(0xFF81C784),
],
),
),
child: SafeArea(
child: Center(
child: SingleChildScrollView(
padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20.0),
child: FadeTransition(
opacity: _fadeAnimation,
child: SlideTransition(
position: _slideAnimation,
child: Column(
mainAxisAlignment: MainAxisAlignment.center,
children: [
_buildLogoSection(),
const SizedBox(height: 30),
_buildSignUpCard(),
const SizedBox(height: 20),
],
),
),
),
),
),
),
),
);
}

Widget _buildLogoSection() {
return const Column(
children: [
CircleAvatar(
radius: 50,
backgroundColor: Colors.white,
child: Icon(
Icons.agriculture,
size: 50,
color: Color(0xFF2E7D32),
),
),
SizedBox(height: 16),
Text(
'Join Farm Crate',
style: TextStyle(
fontSize: 28,
fontWeight: FontWeight.bold,
color: Colors.white,
letterSpacing: 1.2,
),
),
SizedBox(height: 8),
Text(
'Create your account to get started',
style: TextStyle(
fontSize: 16,
color: Colors.white70,
fontWeight: FontWeight.w300,
),
),
],
);
}

Widget _buildSignUpCard() {
return Container(
width: double.infinity,
constraints: const BoxConstraints(maxWidth: 400),
decoration: BoxDecoration(
color: Colors.white,
borderRadius: BorderRadius.circular(24),
boxShadow: const [
BoxShadow(
color: Colors.black12,
blurRadius: 30,
offset: Offset(0, 15),
),
],
),
child: Padding(
padding: const EdgeInsets.all(32),
child: Form(
key: _formKey,
child: Column(
crossAxisAlignment: CrossAxisAlignment.start,
children: [
const Text(
'Create Account',
style: TextStyle(
fontSize: 28,
fontWeight: FontWeight.bold,
color: Color(0xFF2E7D32),
),
),
const SizedBox(height: 8),
Text(
'Fill in your details to get started',
style: TextStyle(
fontSize: 16,
color: Colors.grey[600],
fontWeight: FontWeight.w400,
),
),
const SizedBox(height: 24),
_buildRoleDropdown(),
const SizedBox(height: 16),
_buildTextField(
controller: _usernameController,
label: 'Username',
icon: Icons.person_outline,
validator: (value) {
if (value == null || value.trim().isEmpty) {
return 'Please enter your username';
}
if (value.trim().length < 3) {
return 'Username must be at least 3 characters';
}
if (value.trim().length > 20) {
return 'Username must be 20 characters or less';
}
if (!RegExp(r'^[a-zA-Z0-9]+$').hasMatch(value.trim())) {
return 'Username can only contain letters and numbers';
}
return null;
},
),
const SizedBox(height: 16),
_buildTextField(
controller: _phoneController,
label: 'Mobile Number',
icon: Icons.phone_outlined,
keyboardType: TextInputType.phone,
inputFormatters: [
FilteringTextInputFormatter.digitsOnly,
LengthLimitingTextInputFormatter(10),
],
prefixText: '+91 ',
validator: (value) {
if (value == null || value.isEmpty) {
return 'Please enter your mobile number';
}
if (value.length != 10) {
return 'Mobile number must be exactly 10 digits';
}
return null;
},
),
const SizedBox(height: 16),
_buildTextField(
controller: _emailController,
label: 'Email',
icon: Icons.email_outlined,
keyboardType: TextInputType.emailAddress,
validator: (value) {
if (value == null || value.isEmpty) {
return 'Please enter your email';
}
if (!RegExp(r'^[a-zA-Z0-9._%+-]+@gmail\.com$').hasMatch(value)) {
return 'Please enter a valid Gmail address (@gmail.com)';
}
return null;
},
),
const SizedBox(height: 16),
_buildTextField(
controller: _ageController,
label: 'Age',
icon: Icons.cake_outlined,
keyboardType: TextInputType.number,
inputFormatters: [
FilteringTextInputFormatter.digitsOnly,
LengthLimitingTextInputFormatter(2),
],
validator: (value) {
if (value == null || value.isEmpty) {
return 'Please enter your age';
}
final age = int.tryParse(value);
if (age == null || age < 18 || age > 100) {
return 'Age must be between 18 and 100';
}
return null;
},
),
const SizedBox(height: 16),
_buildTextField(
controller: _addressController,
label: 'Address',
icon: Icons.home_outlined,
validator: (value) {
if (value == null || value.isEmpty) {
return 'Please enter your address';
}
if (value.length < 5) {
return 'Address must be at least 5 characters';
}
return null;
},
),
const SizedBox(height: 16),
_buildTextField(
controller: _zoneController,
label: 'Zone',
icon: Icons.map_outlined,
validator: (value) {
if (value == null || value.isEmpty) {
return 'Please enter your zone';
}
return null;
},
),
const SizedBox(height: 16),
_buildAutocompleteField(
controller: _stateController,
label: 'State',
icon: Icons.location_on_outlined,
options: _states,
validator: (value) {
if (value == null || value.isEmpty) {
return 'Please select a state';
}
if (!_states.contains(value)) {
return 'Please select a valid state';
}
return null;
},
isStateField: true,
),
const SizedBox(height: 16),
_buildAutocompleteField(
controller: _districtController,
label: 'District',
icon: Icons.location_city_outlined,
options: _stateDistricts[_stateController.text] ?? [],
validator: (value) {
if (value == null || value.isEmpty) {
return 'Please enter a district';
}
if (!RegExp(r'^[a-zA-Z0-9 ]+?').hasMatch(value)) {
return 'Only letters, numbers and spaces allowed';
}
return null;
},
),
if (_selectedRole == 'Farmer') ...[
const SizedBox(height: 16),
_buildTextField(
controller: _accountNumberController,
label: 'Account Number',
icon: Icons.account_balance_outlined,
keyboardType: TextInputType.number,
inputFormatters: [
FilteringTextInputFormatter.digitsOnly,
LengthLimitingTextInputFormatter(20),
],
validator: (value) {
if (value == null || value.isEmpty) {
return 'Please enter your account number';
}
if (value.length < 9) {
return 'Account number must be at least 9 digits';
}
return null;
},
),
const SizedBox(height: 16),
_buildTextField(
controller: _ifscCodeController,
label: 'IFSC Code',
icon: Icons.code_outlined,
validator: (value) {
if (value == null || value.isEmpty) {
return 'Please enter IFSC code';
}
if (!RegExp(r'^[A-Z]{4}0[A-Z0-9]{6}$').hasMatch(value.toUpperCase())) {
return 'Please enter a valid IFSC code';
}
return null;
},
),
const SizedBox(height: 16),
_buildTextField(
controller: _globalFarmerIdController,
label: 'Global Farmer ID',
icon: Icons.badge_outlined,
inputFormatters: [
FilteringTextInputFormatter.allow(RegExp('[a-zA-Z0-9]')),
],
validator: (value) {
if (value == null || value.isEmpty) {
return 'Please enter Global Farmer ID';
}
if (!RegExp(r'^[a-zA-Z0-9]+$').hasMatch(value)) {
return 'Only letters and numbers allowed';
}
return null;
},
),
],
if (_selectedRole == 'Transport') ...[
const SizedBox(height: 16),
_buildTextField(
controller: _aadharNumberController,
label: 'Aadhar Number',
icon: Icons.credit_card_outlined,
keyboardType: TextInputType.number,
inputFormatters: [
FilteringTextInputFormatter.digitsOnly,
LengthLimitingTextInputFormatter(12),
],
validator: (value) {
if (value == null || value.isEmpty) {
return 'Please enter Aadhar number';
}
if (value.length != 12) {
return 'Aadhar number must be exactly 12 digits';
}
return null;
},
),
const SizedBox(height: 16),
_buildTextField(
controller: _panNumberController,
label: 'PAN Number',
icon: Icons.badge_outlined,
inputFormatters: [
FilteringTextInputFormatter.allow(RegExp('[A-Z0-9]')),
LengthLimitingTextInputFormatter(10),
],
validator: (value) {
if (value == null || value.isEmpty) {
return 'Please enter PAN number';
}
if (!RegExp(r'^[A-Z]{5}[0-9]{4}[A-Z]{1}$').hasMatch(value.toUpperCase())) {
return 'Please enter a valid PAN number (e.g., ABCDE1234F)';
}
return null;
},
),
const SizedBox(height: 16),
_buildTextField(
controller: _voterIdNumberController,
label: 'Voter ID Number',
icon: Icons.how_to_vote_outlined,
inputFormatters: [
FilteringTextInputFormatter.allow(RegExp('[A-Z0-9]')),
LengthLimitingTextInputFormatter(10),
],
validator: (value) {
if (value == null || value.isEmpty) {
return 'Please enter Voter ID number';
}
if (value.length < 3) {
return 'Voter ID must be at least 3 characters';
}
return null;
},
),
const SizedBox(height: 16),
_buildTextField(
controller: _licenseNumberController,
label: 'License Number',
icon: Icons.drive_eta_outlined,
inputFormatters: [
FilteringTextInputFormatter.allow(RegExp('[A-Z0-9-]')),
LengthLimitingTextInputFormatter(20),
],
validator: (value) {
if (value == null || value.isEmpty) {
return 'Please enter License number';
}
if (value.length < 5) {
return 'License number must be at least 5 characters';
}
return null;
},
),
const SizedBox(height: 16),
_buildTextField(
controller: _accountNumberController,
label: 'Account Number',
icon: Icons.account_balance_outlined,
keyboardType: TextInputType.number,
inputFormatters: [
FilteringTextInputFormatter.digitsOnly,
LengthLimitingTextInputFormatter(20),
],
validator: (value) {
if (value == null || value.isEmpty) {
return 'Please enter your account number';
}
if (value.length < 9) {
return 'Account number must be at least 9 digits';
}
return null;
},
),
const SizedBox(height: 16),
_buildTextField(
controller: _ifscCodeController,
label: 'IFSC Code',
icon: Icons.code_outlined,
inputFormatters: [
FilteringTextInputFormatter.allow(RegExp('[A-Z0-9]')),
LengthLimitingTextInputFormatter(11),
],
validator: (value) {
if (value == null || value.isEmpty) {
return 'Please enter IFSC code';
}
if (!RegExp(r'^[A-Z]{4}0[A-Z0-9]{6}$').hasMatch(value.toUpperCase())) {
return 'Please enter a valid IFSC code';
}
return null;
},
),
const SizedBox(height: 16),
_buildDocumentPickers(),
],
const SizedBox(height: 16),
_buildImagePicker(),
const SizedBox(height: 16),
_buildTextField(
controller: _passwordController,
label: 'Password',
icon: Icons.lock_outline,
isPassword: true,
isPasswordVisible: _isPasswordVisible,
enableInteractiveSelection: false,
onTogglePassword: () {
setState(() {
_isPasswordVisible = !_isPasswordVisible;
});
},
validator: (value) {
if (value == null || value.isEmpty) {
return 'Please enter a password';
}
if (value.length < 4) {
return 'Password must be at least 4 characters';
}
if (value.length > 8) {
return 'Password must be 8 or fewer characters';
}
return null;
},
),
const SizedBox(height: 16),
_buildTextField(
controller: _confirmPasswordController,
label: 'Confirm Password',
icon: Icons.lock_outline,
isPassword: true,
isPasswordVisible: _isConfirmPasswordVisible,
enableInteractiveSelection: false,
onTogglePassword: () {
setState(() {
_isConfirmPasswordVisible = !_isConfirmPasswordVisible;
});
},
validator: (value) {
if (value == null || value.isEmpty) {
return 'Please confirm your password';
}
if (value != _passwordController.text) {
return 'Passwords do not match';
}
return null;
},
),
const SizedBox(height: 24),
_buildSignUpButton(),
const SizedBox(height: 16),
Row(
children: [
Expanded(child: Divider(color: Colors.grey[400])),
Padding(
padding: EdgeInsets.symmetric(horizontal: 16),
child: Text('OR', style: TextStyle(color: Colors.grey[600])),
),
Expanded(child: Divider(color: Colors.grey[400])),
],
),
const SizedBox(height: 16),
Container(
width: double.infinity,
height: 56,
child: ElevatedButton(
onPressed: _isLoading ? null : _handleGoogleSignUp,
style: ElevatedButton.styleFrom(
backgroundColor: Colors.white,
foregroundColor: Colors.black87,
elevation: 2,
shadowColor: Colors.black26,
shape: RoundedRectangleBorder(
borderRadius: BorderRadius.circular(28),
side: BorderSide(color: Colors.grey[300]!, width: 1),
),
padding: EdgeInsets.symmetric(horizontal: 16),
),
child: Row(
mainAxisAlignment: MainAxisAlignment.center,
children: [
Image.asset(
'assets/icons8-google-logo-50.png',
width: 20,
height: 20,
),
SizedBox(width: 12),
Text(
'Continue with Google',
style: TextStyle(
fontSize: 15,
fontWeight: FontWeight.w500,
color: Colors.black87,
),
),
],
),
),
),
const SizedBox(height: 16),
Wrap(
alignment: WrapAlignment.center,
children: [
Text(
'Already have an account? ',
style: TextStyle(
fontSize: 14,
color: Colors.grey[600],
fontWeight: FontWeight.w400,
),
),
GestureDetector(
onTap: () {
Navigator.pushReplacement(
context,
MaterialPageRoute(builder: (context) =>  LoginPage()),
);
},
child: const Text(
'SignIn',
style: TextStyle(
fontSize: 14,
color: Color(0xFF4CAF50),
fontWeight: FontWeight.w600,
decoration: TextDecoration.underline,
),
),
),
],
),
SizedBox(height: 8),
],
),
),
),
);
}

Widget _buildRoleDropdown() {
return Column(
crossAxisAlignment: CrossAxisAlignment.start,
children: [
const Text(
'Role',
style: TextStyle(
fontSize: 16,
color: Colors.grey,
fontWeight: FontWeight.w500,
),
),
const SizedBox(height: 8),
Container(
width: double.infinity,
padding: const EdgeInsets.symmetric(horizontal: 12),
decoration: BoxDecoration(
border: Border.all(color: Colors.grey[300]!),
borderRadius: BorderRadius.circular(12),
color: Colors.grey[50],
),
child: DropdownButtonFormField<String>(
value: _selectedRole,
isExpanded: true,
icon: const Icon(Icons.arrow_drop_down, color: Color(0xFF4CAF50)),
style: TextStyle(
color: Colors.grey[800],
fontSize: 16,
),
onChanged: (String? newValue) {
setState(() {
_selectedRole = newValue;
// Clear fields that are not applicable to other roles
if (newValue != 'Farmer') {
_accountNumberController.clear();
_ifscCodeController.clear();
}
if (newValue != 'Transport') {
_aadharNumberController.clear();
_panNumberController.clear();
_voterIdNumberController.clear();
_licenseNumberController.clear();
_selectedAadharFile = null;
_selectedPanFile = null;
_selectedVoterIdFile = null;
_selectedLicenseFile = null;
}
// Clear image when role changes so user can select appropriate image
_selectedImage = null;
});
},
items: _roles.map<DropdownMenuItem<String>>((String value) {
IconData roleIcon;
switch (value) {
case 'Farmer':
roleIcon = Icons.agriculture;
break;
case 'Customer':
roleIcon = Icons.shopping_cart;
break;
case 'Transport':
roleIcon = Icons.local_shipping;
break;
default:
roleIcon = Icons.person;
}
return DropdownMenuItem<String>(
value: value,
child: Row(
children: [
Icon(roleIcon, color: const Color(0xFF4CAF50), size: 20),
const SizedBox(width: 12),
Text(value),
],
),
);
}).toList(),
validator: (value) => value == null ? 'Please select a role' : null,
decoration: const InputDecoration(
border: InputBorder.none,
),
),
),
],
);
}

Widget _buildImagePicker() {
return Column(
crossAxisAlignment: CrossAxisAlignment.start,
children: [
Text(
_getImageLabel(),
style: const TextStyle(
fontSize: 16,
color: Colors.grey,
fontWeight: FontWeight.w500,
),
),
const SizedBox(height: 8),
GestureDetector(
onTap: _pickImage,
child: Container(
width: double.infinity,
height: 120,
decoration: BoxDecoration(
border: Border.all(color: Colors.grey[300]!),
borderRadius: BorderRadius.circular(12),
color: Colors.grey[50],
),
child: _selectedImage != null
? ClipRRect(
borderRadius: BorderRadius.circular(12),
child: Image.file(_selectedImage!, fit: BoxFit.cover),
)
    : Column(
mainAxisAlignment: MainAxisAlignment.center,
children: [
Icon(
_selectedRole == 'Transport'
? Icons.photo
    : Icons.camera_alt_outlined,
size: 40,
color: const Color(0xFF4CAF50),
),
const SizedBox(height: 8),
Text(
_getImagePlaceholderText(),
style: const TextStyle(
color: Colors.grey,
fontSize: 14,
),
),
],
),
),
),
],
);
}

Widget _buildDocumentPickers() {
return Column(
crossAxisAlignment: CrossAxisAlignment.start,
children: [
const Text(
'Required Documents',
style: TextStyle(
fontSize: 18,
fontWeight: FontWeight.bold,
color: Color(0xFF2E7D32),
),
),
const SizedBox(height: 16),
_buildDocumentPicker(
label: 'Aadhar Card',
file: _selectedAadharFile,
onTap: () => _pickDocument('aadhar'),
icon: Icons.credit_card,
),
const SizedBox(height: 12),
_buildDocumentPicker(
label: 'PAN Card',
file: _selectedPanFile,
onTap: () => _pickDocument('pan'),
icon: Icons.badge,
),
const SizedBox(height: 12),
_buildDocumentPicker(
label: 'Voter ID',
file: _selectedVoterIdFile,
onTap: () => _pickDocument('voter'),
icon: Icons.how_to_vote,
),
const SizedBox(height: 12),
_buildDocumentPicker(
label: 'Driving License',
file: _selectedLicenseFile,
onTap: () => _pickDocument('license'),
icon: Icons.drive_eta,
),
],
);
}

Widget _buildDocumentPicker({
required String label,
required File? file,
required VoidCallback onTap,
required IconData icon,
}) {
return GestureDetector(
onTap: onTap,
child: Container(
width: double.infinity,
height: 60,
decoration: BoxDecoration(
border: Border.all(
color: file != null ? const Color(0xFF4CAF50) : Colors.grey[300]!,
width: file != null ? 2 : 1,
),
borderRadius: BorderRadius.circular(12),
color: file != null ? const Color(0xFF4CAF50).withValues(alpha: 0.1) : Colors.grey[50],
),
child: Padding(
padding: const EdgeInsets.symmetric(horizontal: 16),
child: Row(
children: [
Icon(
icon,
color: file != null ? const Color(0xFF4CAF50) : Colors.grey[600],
size: 24,
),
const SizedBox(width: 12),
Expanded(
child: Text(
file != null ? '$label - Selected' : 'Tap to select $label',
style: TextStyle(
color: file != null ? const Color(0xFF4CAF50) : Colors.grey[600],
fontWeight: file != null ? FontWeight.w600 : FontWeight.w400,
fontSize: 14,
),
),
),
if (file != null)
const Icon(
Icons.check_circle,
color: Color(0xFF4CAF50),
size: 20,
),
],
),
),
),
);
}

Widget _buildTextField({
required TextEditingController controller,
required String label,
required IconData icon,
bool isPassword = false,
bool isPasswordVisible = false,
bool enableInteractiveSelection = true,
VoidCallback? onTogglePassword,
TextInputType? keyboardType,
List<TextInputFormatter>? inputFormatters,
String? Function(String?)? validator,
String? prefixText,
}) {
return TextFormField(
controller: controller,
obscureText: isPassword && !isPasswordVisible,
keyboardType: keyboardType,
inputFormatters: inputFormatters,
enableInteractiveSelection: enableInteractiveSelection,
validator: validator,
decoration: InputDecoration(
labelText: label,
prefixIcon: Icon(icon, color: const Color(0xFF4CAF50)),
suffixIcon: isPassword
? IconButton(
icon: Icon(
isPasswordVisible ? Icons.visibility : Icons.visibility_off,
color: const Color(0xFF4CAF50),
),
onPressed: onTogglePassword,
)
    : null,
border: OutlineInputBorder(
borderRadius: BorderRadius.circular(12),
borderSide: BorderSide(color: Colors.grey[300]!),
),
focusedBorder: OutlineInputBorder(
borderRadius: BorderRadius.circular(12),
borderSide: const BorderSide(color: Color(0xFF4CAF50), width: 2),
),
errorBorder: OutlineInputBorder(
borderRadius: BorderRadius.circular(12),
borderSide: const BorderSide(color: Colors.red, width: 2),
),
filled: true,
fillColor: Colors.grey[50],
labelStyle: const TextStyle(color: Colors.grey),
prefixText: prefixText,
),
);
}

Widget _buildAutocompleteField({
required TextEditingController controller,
required String label,
required IconData icon,
required List<String> options,
String? Function(String?)? validator,
bool isStateField = false,
}) {
return Autocomplete<String>(
optionsBuilder: (TextEditingValue textEditingValue) {
if (textEditingValue.text.isEmpty) {
return const Iterable<String>.empty();
}
return options.where((String option) =>
option.toLowerCase().startsWith(textEditingValue.text.toLowerCase()));
},
onSelected: (String selection) {
controller.text = selection;
if (isStateField) {
_districtController.clear();
setState(() {});
}
},
fieldViewBuilder: (
BuildContext context,
TextEditingController textEditingController,
FocusNode focusNode,
VoidCallback onFieldSubmitted,
) {
textEditingController.text = controller.text;
textEditingController.addListener(() {
controller.text = textEditingController.text;
});
return TextFormField(
controller: textEditingController,
focusNode: focusNode,
validator: validator,
decoration: InputDecoration(
labelText: label,
prefixIcon: Icon(icon, color: const Color(0xFF4CAF50)),
border: OutlineInputBorder(
borderRadius: BorderRadius.circular(12),
borderSide: BorderSide(color: Colors.grey[300]!),
),
focusedBorder: OutlineInputBorder(
borderRadius: BorderRadius.circular(12),
borderSide: const BorderSide(color: Color(0xFF4CAF50), width: 2),
),
errorBorder: OutlineInputBorder(
borderRadius: BorderRadius.circular(12),
borderSide: const BorderSide(color: Colors.red, width: 2),
),
filled: true,
fillColor: Colors.grey[50],
labelStyle: const TextStyle(color: Colors.grey),
),
);
},
optionsViewBuilder: (
BuildContext context,
AutocompleteOnSelected<String> onSelected,
Iterable<String> options,
) {
return Align(
alignment: Alignment.topLeft,
child: Material(
elevation: 4,
child: ConstrainedBox(
constraints: const BoxConstraints(maxHeight: 200),
child: ListView.builder(
shrinkWrap: true,
itemCount: options.length,
itemBuilder: (BuildContext context, int index) {
final String option = options.elementAt(index);
return GestureDetector(
onTap: () => onSelected(option),
child: ListTile(title: Text(option)),
);
},
),
),
),
);
},
);
}

Widget _buildSignUpButton() {
return SizedBox(
width: double.infinity,
height: 56,
child: ElevatedButton(
onPressed: _isLoading ? null : _handleSignUp,
style: ElevatedButton.styleFrom(
backgroundColor: const Color(0xFF4CAF50),
foregroundColor: Colors.white,
shape: RoundedRectangleBorder(
borderRadius: BorderRadius.circular(16),
),
elevation: 8,
shadowColor: const Color(0xFF4CAF50).withValues(alpha: 0.3),
),
child: _isLoading
? const SizedBox(
width: 24,
height: 24,
child: CircularProgressIndicator(
color: Colors.white,
strokeWidth: 2,
),
)
    : const Text(
'Create Account',
style: TextStyle(
fontSize: 18,
fontWeight: FontWeight.bold,
),
),
),
);
}

void showSuccessDialog(String title, String message, {VoidCallback? onOk}) {
showDialog(
context: context,
barrierDismissible: false,
builder: (context) => Dialog(
shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
backgroundColor: Colors.white,
child: Padding(
padding: const EdgeInsets.all(24.0),
child: Column(
mainAxisSize: MainAxisSize.min,
children: [
Icon(Icons.celebration, color: Color(0xFF4CAF50), size: 60),
SizedBox(height: 16),
Text(
title,
style: TextStyle(
color: Color(0xFF2E7D32),
fontWeight: FontWeight.bold,
fontSize: 22,
),
textAlign: TextAlign.center,
),
SizedBox(height: 12),
Text(
message,
style: TextStyle(
color: Color(0xFF388E3C),
fontSize: 16,
),
textAlign: TextAlign.center,
),
SizedBox(height: 24),
ElevatedButton(
style: ElevatedButton.styleFrom(
backgroundColor: Color(0xFF4CAF50),
foregroundColor: Colors.white,
shape: RoundedRectangleBorder(
borderRadius: BorderRadius.circular(12),
),
padding: EdgeInsets.symmetric(horizontal: 32, vertical: 12),
),
onPressed: () {
Navigator.of(context).pop();
if (onOk != null) onOk();
},
child: Text('OK', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
),
],
),
),
),
);
}
}





