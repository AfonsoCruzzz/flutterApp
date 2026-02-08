import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart' hide User;
import 'package:provider/provider.dart';
import '../models/user.dart';
import '../models/veterinarian.dart';
import '../models/service_provider.dart';
import '../providers/user_provider.dart';

// IMPORTA OS TEUS NOVOS WIDGETS
import '../widgets/profile_tabs/general_tab.dart';
import '../widgets/profile_tabs/veterinarian_tab.dart';
import '../widgets/profile_tabs/provider_tab.dart';

class EditProfileScreen extends StatefulWidget {
  final Veterinarian? veterinarian;
  final ServiceProvider? provider;

  const EditProfileScreen({super.key, this.veterinarian, this.provider});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _supabase = Supabase.instance.client;
  final _picker = ImagePicker();
  
  late TabController _tabController;
  bool _initialized = false;
  bool _isSaving = false;
  late User _user;

  // --- CONTROLADORES E ESTADOS ---

  // 1. GERAL (Comum)
  File? _imageFile;
  String? _currentPhotoUrl;
  final _nameCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _districtCtrl = TextEditingController();
  final _municipalityCtrl = TextEditingController();
  final _addressCtrl = TextEditingController();
  final _providerAddressCtrl = TextEditingController();
  final _providerDistrictCtrl = TextEditingController();
  final _providerMunicipalityCtrl = TextEditingController();
  bool _hasOtherPets = false;


  // 2. VETERINÁRIO
  final _bioVetCtrl = TextEditingController();
  final _clinicNameCtrl = TextEditingController();
  String _serviceType = 'clinic';
  List<String> _selectedSpecies = [];
  List<String> _selectedSpecialties = [];

  // 3. PRESTADOR (Provider)
  final _bioProviderCtrl = TextEditingController();
  // Mapa de Serviços Ativos
  final Map<String, bool> _activeProviderServices = {
    'pet_boarding': false, 'pet_day_care': false, 'pet_sitting': false,
    'dog_walking': false, 'pet_taxi': false, 'pet_grooming': false, 'pet_training': false,
  };
  // Preços
  final Map<String, TextEditingController> _priceControllers = {};
  
  // Logística e Casa
  String _housingType = 'Apartamento';
  bool _hasFencedYard = false;
  bool _hasEmergencyTransport = false;
  double _serviceRadiusKm = 10.0;
  
  // NOVAS LISTAS (Skills e Pets)
  List<String> _acceptedPets = [];
  List<String> _providerSkills = [];

  @override
  void initState() {
    super.initState();
    // Iniciar controllers de preço para cada serviço possível
    for (var key in _activeProviderServices.keys) {
      _priceControllers[key] = TextEditingController();
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_initialized) {
      final userProvider = Provider.of<UserProvider>(context);
      if (userProvider.currentUser == null) {
        Navigator.pop(context);
        return;
      }
      _user = userProvider.currentUser!;
      _currentPhotoUrl = _user.photo;

      // 1. Configurar Abas
      bool isVet = _user.type == UserType.veterinarian;
      bool isProvider = _user.type == UserType.serviceProvider || widget.provider != null;
      
      // Conta quantas abas vamos ter (Geral é fixa = 1)
      int tabCount = 1 + (isVet ? 1 : 0) + (isProvider ? 1 : 0);
      _tabController = TabController(length: tabCount, vsync: this);

      // 2. Carregar Dados GERAIS
      _nameCtrl.text = _user.name;
      _phoneCtrl.text = _user.phone ?? '';
      _districtCtrl.text = _user.district ?? '';
      _municipalityCtrl.text = _user.city ?? '';
      _addressCtrl.text = _user.address ?? '';

      // 3. Carregar Dados VETERINÁRIO
      if (isVet && widget.veterinarian != null) {
        final v = widget.veterinarian!;
        _bioVetCtrl.text = v.bio;
        _clinicNameCtrl.text = v.clinicName ?? '';
        _serviceType = v.serviceType;
        _selectedSpecies = List.from(v.species);
        _selectedSpecialties = List.from(v.specialties);
      }

      // 4. Carregar Dados PRESTADOR
      if (isProvider && widget.provider != null) {
        final p = widget.provider!;
        _bioProviderCtrl.text = p.description;
        _housingType = p.housingType;
        _hasFencedYard = p.hasFencedYard;
        _hasEmergencyTransport = p.hasEmergencyTransport;
        _serviceRadiusKm = p.serviceRadiusKm.toDouble();
        _hasOtherPets = p.hasOtherPets;
        _providerAddressCtrl.text = p.address ?? '';
        _providerDistrictCtrl.text = p.district ?? '';
        _providerMunicipalityCtrl.text = p.municipality ?? '';
        // Carregar listas novas
        _acceptedPets = List.from(p.acceptedPets);
        _providerSkills = List.from(p.skills);

        // Carregar Serviços e Preços
        for (var s in p.serviceTypes) {
          if (_activeProviderServices.containsKey(s)) {
            _activeProviderServices[s] = true;
            _priceControllers[s]?.text = p.prices[s]?.toStringAsFixed(2) ?? '';
          }
        }
      }
      _initialized = true;
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    // Limpar memória
    _nameCtrl.dispose(); _phoneCtrl.dispose(); _districtCtrl.dispose(); 
    _municipalityCtrl.dispose(); _addressCtrl.dispose();
    _bioVetCtrl.dispose(); _clinicNameCtrl.dispose();
    _bioProviderCtrl.dispose();
    for (var c in _priceControllers.values) c.dispose();
    super.dispose();
  }

  Future<void> _saveAll() async {
    if (!_formKey.currentState!.validate()) {
       ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Corrija os erros assinalados a vermelho.")));
       return;
    }
    setState(() => _isSaving = true);
    
    try {
      final uid = _user.id;
      
      // 1. Upload da Foto (se mudou)
      String? newPhotoUrl = _currentPhotoUrl;
      if (_imageFile != null) {
        final fileName = '$uid-${DateTime.now().millisecondsSinceEpoch}.${_imageFile!.path.split('.').last}';
        await _supabase.storage.from('avatars').upload(fileName, _imageFile!);
        newPhotoUrl = _supabase.storage.from('avatars').getPublicUrl(fileName);
      }

      // 2. Atualizar Perfil Base (Tabela profiles)
      await _supabase.from('profiles').update({
        'full_name': _nameCtrl.text.trim(),
        'phone': _phoneCtrl.text.trim(),
        'photo': newPhotoUrl,
        'district': _districtCtrl.text.trim(),
        'city': _municipalityCtrl.text.trim(),
        'address': _addressCtrl.text.trim(),
      }).eq('id', uid);

      // 3. Atualizar Veterinário (Tabela veterinarians)
      if (_user.type == UserType.veterinarian) {
        await _supabase.from('veterinarians').update({
          'bio': _bioVetCtrl.text.trim(),
          'photo': newPhotoUrl,
          'service_type': _serviceType,
          'clinic_name': _serviceType == 'independent' ? null : _clinicNameCtrl.text.trim(),
          'species': _selectedSpecies,
          'specialties': _selectedSpecialties,
          // Sincronizar localização
          'district': _districtCtrl.text.trim(),
          'city': _municipalityCtrl.text.trim(),
          'address': _addressCtrl.text.trim(),
        }).eq('id', uid);
      }

      // 4. Atualizar Prestador (Tabela providers)
      if (_user.type == UserType.serviceProvider || widget.provider != null) {
        // Compilar serviços ativos e preços
        List<String> services = [];
        Map<String, double> prices = {};
        _activeProviderServices.forEach((k, v) {
          if (v) {
            services.add(k);
            // Converter texto para double (ex: "12,50" -> 12.50)
            prices[k] = double.tryParse(_priceControllers[k]!.text.replaceAll(',', '.')) ?? 0.0;
          }
        });

        // Criar objeto
        final pData = ServiceProvider(
          id: uid, 
          description: _bioProviderCtrl.text.trim(),
          serviceTypes: services, 
          prices: prices,
          housingType: _housingType, 
          hasFencedYard: _hasFencedYard,
          hasYard: false, // Podes adicionar switch para isto se quiseres
          hasOtherPets: _hasOtherPets, 
          
          acceptedPets: _acceptedPets, // <--- CAMPO IMPORTANTE
          skills: _providerSkills,     // <--- CAMPO IMPORTANTE
          
          hasEmergencyTransport: _hasEmergencyTransport,
          serviceRadiusKm: _serviceRadiusKm.round(),
          gallery: [], isActive: true, yearsExperience: 0, ratingAvg: 0, ratingCount: 0,
          address: _providerAddressCtrl.text.trim(), 
          district: _providerDistrictCtrl.text.trim(),
          municipality: _providerMunicipalityCtrl.text.trim(),
        );
        
        // Gravar na BD (Upsert = Inserir ou Atualizar)
        await _supabase.from('providers').upsert(pData.toMap());
      }

      if (mounted) {
        await context.read<UserProvider>().refreshUser();
        Navigator.pop(context, true);
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Perfil atualizado com sucesso!")));
      }
    } catch (e) {
      if(mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Erro: $e")));
    } finally {
      if(mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_initialized) return const Scaffold(body: Center(child: CircularProgressIndicator()));
    
    bool isVet = _user.type == UserType.veterinarian;
    bool isProvider = _user.type == UserType.serviceProvider || widget.provider != null;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Editar Perfil'),
        actions: [
          IconButton(
            icon: _isSaving 
              ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
              : const Icon(Icons.check),
            onPressed: _isSaving ? null : _saveAll,
          )
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          tabs: [
            const Tab(text: "Geral", icon: Icon(Icons.person)),
            if (isVet) const Tab(text: "Veterinário", icon: Icon(Icons.medical_services)),
            if (isProvider) const Tab(text: "Serviços Pet", icon: Icon(Icons.pets)),
          ],
        ),
      ),
      body: Form(
        key: _formKey,
        child: TabBarView(
          controller: _tabController,
          children: [
            // --- TAB 1: GERAL ---
            GeneralTab(
              nameController: _nameCtrl, phoneController: _phoneCtrl,
              districtController: _districtCtrl, municipalityController: _municipalityCtrl,
              addressController: _addressCtrl,
              imageFile: _imageFile, currentPhotoUrl: _currentPhotoUrl,
              onImagePick: () async {
                 final picked = await _picker.pickImage(source: ImageSource.gallery);
                 if (picked != null) setState(() => _imageFile = File(picked.path));
              },
            ),
            
            // --- TAB 2: VETERINÁRIO ---
            if (isVet)
              VeterinarianTab(
                bioController: _bioVetCtrl, clinicNameController: _clinicNameCtrl,
                serviceType: _serviceType, selectedSpecies: _selectedSpecies, selectedSpecialties: _selectedSpecialties,
                onServiceTypeChanged: (v) => setState(() => _serviceType = v!),
                onSpeciesChanged: (l) => setState(() => _selectedSpecies = l),
                onSpecialtiesChanged: (l) => setState(() => _selectedSpecialties = l),
              ),
              
            // --- TAB 3: PRESTADOR ---
            if (isProvider)
              ProviderTab(
                bioController: _bioProviderCtrl,
                activeServices: _activeProviderServices, 
                priceControllers: _priceControllers,
                radius: _serviceRadiusKm, 
                hasTransport: _hasEmergencyTransport,
                housingType: _housingType, 
                hasFencedYard: _hasFencedYard,
                
                acceptedPets: _acceptedPets, // Passar a lista
                skills: _providerSkills,     // Passar a lista
                
                // Callbacks para atualizar o estado aqui no Pai
                onServiceChanged: (k, v) => setState(() => _activeProviderServices[k] = v),
                onRadiusChanged: (v) => setState(() => _serviceRadiusKm = v),
                onTransportChanged: (v) => setState(() => _hasEmergencyTransport = v),
                onHousingChanged: (v) => setState(() => _housingType = v!),
                onFenceChanged: (v) => setState(() => _hasFencedYard = v),
                onAcceptedPetsChanged: (l) => setState(() => _acceptedPets = l),
                onSkillsChanged: (l) => setState(() => _providerSkills = l),
                hasOtherPets: _hasOtherPets,
                onOtherPetsChanged: (v) => setState(() => _hasOtherPets = v),
                addressController: _providerAddressCtrl,
                districtController: _providerDistrictCtrl,
                municipalityController: _providerMunicipalityCtrl,
              ),
          ],
        ),
      ),
    );
  }
}