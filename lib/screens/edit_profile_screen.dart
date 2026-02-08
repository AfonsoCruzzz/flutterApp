import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart' hide User;
import 'package:provider/provider.dart';

// MODELS
import '../models/user.dart';
import '../models/veterinarian.dart';
import '../models/service_provider.dart';
import '../models/working_schedule.dart'; // <--- Não esquecer este import

// PROVIDERS
import '../providers/user_provider.dart';

// WIDGETS (TABS)
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

  // --- 1. GERAL (Comum) ---
  File? _imageFile;
  String? _currentPhotoUrl;
  final _nameCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _districtCtrl = TextEditingController();
  final _municipalityCtrl = TextEditingController();
  final _addressCtrl = TextEditingController();
  
  // Variável de Estado para o Horário (Partilhado entre Vet e Provider)
  WorkingSchedule _schedule = WorkingSchedule.empty();

  // --- 2. VETERINÁRIO ---
  final _bioVetCtrl = TextEditingController();
  final _clinicNameCtrl = TextEditingController();
  String _serviceType = 'clinic';
  List<String> _selectedSpecies = [];
  List<String> _selectedSpecialties = [];

  // --- 3. PRESTADOR (Provider) ---
  final _bioProviderCtrl = TextEditingController();
  final _providerAddressCtrl = TextEditingController();
  final _providerDistrictCtrl = TextEditingController();
  final _providerMunicipalityCtrl = TextEditingController();
  
  // Mapa de Serviços Ativos
  final Map<String, bool> _activeProviderServices = {
    'pet_boarding': false, 'pet_day_care': false, 'pet_sitting': false,
    'dog_walking': false, 'pet_taxi': false, 'pet_grooming': false, 'pet_training': false,
  };
  final Map<String, TextEditingController> _priceControllers = {};
  
  String _housingType = 'Apartamento';
  bool _hasFencedYard = false;
  bool _hasEmergencyTransport = false;
  bool _hasOtherPets = false;
  double _serviceRadiusKm = 10.0;
  
  List<String> _acceptedPets = [];
  List<String> _providerSkills = [];

  @override
  void initState() {
    super.initState();
    // Iniciar controllers de preço
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

      // Definir quais abas mostrar
      bool isVet = _user.type == UserType.veterinarian;
      bool isProvider = _user.type == UserType.serviceProvider || widget.provider != null;
      
      int tabCount = 1 + (isVet ? 1 : 0) + (isProvider ? 1 : 0);
      _tabController = TabController(length: tabCount, vsync: this);

      // --- CARREGAR DADOS ---

      // 1. Geral
      _nameCtrl.text = _user.name;
      _phoneCtrl.text = _user.phone ?? '';
      _districtCtrl.text = _user.district ?? '';
      _municipalityCtrl.text = _user.city ?? '';
      _addressCtrl.text = _user.address ?? '';

      // 2. Horário (Lógica de prioridade: Provider > Vet > Vazio)
      // Se tivermos um provider carregado e ele tiver horário, usamos esse.
      // Se não, tentamos o do veterinário.
      if (widget.provider?.schedule != null) {
        _schedule = widget.provider!.schedule!;
      } else if (widget.veterinarian?.schedule != null) {
        _schedule = widget.veterinarian!.schedule!;
      }

      // 3. Veterinário
      if (isVet && widget.veterinarian != null) {
        final v = widget.veterinarian!;
        _bioVetCtrl.text = v.bio;
        _clinicNameCtrl.text = v.clinicName ?? '';
        _serviceType = v.serviceType;
        _selectedSpecies = List.from(v.species);
        _selectedSpecialties = List.from(v.specialties);
        // Nota: O schedule já foi tratado acima para evitar conflitos
      }

      // 4. Prestador
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
        
        _acceptedPets = List.from(p.acceptedPets);
        _providerSkills = List.from(p.skills);

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
    _nameCtrl.dispose(); _phoneCtrl.dispose(); _districtCtrl.dispose(); 
    _municipalityCtrl.dispose(); _addressCtrl.dispose();
    _bioVetCtrl.dispose(); _clinicNameCtrl.dispose();
    _bioProviderCtrl.dispose();
    _providerAddressCtrl.dispose(); _providerDistrictCtrl.dispose(); _providerMunicipalityCtrl.dispose();
    for (var c in _priceControllers.values) c.dispose();
    super.dispose();
  }

  Future<void> _saveAll() async {
    if (!_formKey.currentState!.validate()) {
       ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Corrija os erros assinalados.")));
       return;
    }
    setState(() => _isSaving = true);
    
    try {
      final uid = _user.id;
      
      // 1. Upload Foto
      String? newPhotoUrl = _currentPhotoUrl;
      if (_imageFile != null) {
        final fileName = '$uid-${DateTime.now().millisecondsSinceEpoch}.${_imageFile!.path.split('.').last}';
        await _supabase.storage.from('avatars').upload(fileName, _imageFile!);
        newPhotoUrl = _supabase.storage.from('avatars').getPublicUrl(fileName);
      }

      // 2. Atualizar Profile
      await _supabase.from('profiles').update({
        'full_name': _nameCtrl.text.trim(),
        'phone': _phoneCtrl.text.trim(),
        'photo': newPhotoUrl,
        'district': _districtCtrl.text.trim(),
        'city': _municipalityCtrl.text.trim(),
        'address': _addressCtrl.text.trim(),
      }).eq('id', uid);

      // 3. Atualizar Veterinário
      if (_user.type == UserType.veterinarian) {
        await _supabase.from('veterinarians').update({
          'bio': _bioVetCtrl.text.trim(),
          'photo': newPhotoUrl,
          'service_type': _serviceType,
          'clinic_name': _serviceType == 'independent' ? null : _clinicNameCtrl.text.trim(),
          'species': _selectedSpecies,
          'specialties': _selectedSpecialties,
          
          // IMPORTANTE: Guardar o horário aqui
          'working_schedule': _schedule.toMap(), // Certifica-te que a coluna existe no Supabase (JSONB)
          
          'district': _districtCtrl.text.trim(),
          'municipality': _municipalityCtrl.text.trim(), // Atenção ao nome da coluna na DB (city vs municipality)
        }).eq('id', uid);
      }

      // 4. Atualizar Provider
      if (_user.type == UserType.serviceProvider || widget.provider != null) {
        // Preparar listas e mapas
        List<String> services = [];
        Map<String, double> prices = {};
        _activeProviderServices.forEach((k, v) {
          if (v) {
            services.add(k);
            prices[k] = double.tryParse(_priceControllers[k]!.text.replaceAll(',', '.')) ?? 0.0;
          }
        });

        final providerMap = {
          'id': uid,
          'description': _bioProviderCtrl.text.trim(),
          'service_types': services,
          'prices': prices,
          'housing_type': _housingType,
          'has_fenced_yard': _hasFencedYard,
          'has_other_pets': _hasOtherPets,
          'accepted_pets': _acceptedPets,
          'skills': _providerSkills,
          'service_radius_km': _serviceRadiusKm.round(),
          'has_emergency_transport': _hasEmergencyTransport,
          'address': _providerAddressCtrl.text.trim(),
          'district': _providerDistrictCtrl.text.trim(),
          'municipality': _providerMunicipalityCtrl.text.trim(),
          'is_active': true,
          
          // IMPORTANTE: Guardar o horário aqui também
          'working_schedule': _schedule.toMap(), // Certifica-te que a coluna existe no Supabase (JSONB)
        };

        await _supabase.from('providers').upsert(providerMap);
      }

      if (mounted) {
        await context.read<UserProvider>().refreshUser();
        Navigator.pop(context, true);
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Perfil atualizado!")));
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

    // Criamos a lista de tabs dinamicamente
    List<Widget> tabs = [const Tab(text: "Geral", icon: Icon(Icons.person))];
    if (isVet) tabs.add(const Tab(text: "Veterinário", icon: Icon(Icons.medical_services)));
    if (isProvider) tabs.add(const Tab(text: "Serviços Pet", icon: Icon(Icons.pets)));

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
          tabs: tabs,
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
                serviceType: _serviceType, 
                selectedSpecies: _selectedSpecies, 
                selectedSpecialties: _selectedSpecialties,
                
                // Callbacks básicos
                onServiceTypeChanged: (v) => setState(() => _serviceType = v!),
                onSpeciesChanged: (l) => setState(() => _selectedSpecies = l),
                onSpecialtiesChanged: (l) => setState(() => _selectedSpecialties = l),
                
                // --- AQUI ESTÁ A LIGAÇÃO DO CALENDÁRIO ---
                currentSchedule: _schedule, 
                onScheduleChanged: (newSchedule) {
                  setState(() {
                    _schedule = newSchedule;
                  });
                },
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
                acceptedPets: _acceptedPets, 
                skills: _providerSkills,
                hasOtherPets: _hasOtherPets,
                addressController: _providerAddressCtrl,
                districtController: _providerDistrictCtrl,
                municipalityController: _providerMunicipalityCtrl,

                // Callbacks básicos
                onServiceChanged: (k, v) => setState(() => _activeProviderServices[k] = v),
                onRadiusChanged: (v) => setState(() => _serviceRadiusKm = v),
                onTransportChanged: (v) => setState(() => _hasEmergencyTransport = v),
                onHousingChanged: (v) => setState(() => _housingType = v!),
                onFenceChanged: (v) => setState(() => _hasFencedYard = v),
                onAcceptedPetsChanged: (l) => setState(() => _acceptedPets = l),
                onSkillsChanged: (l) => setState(() => _providerSkills = l),
                onOtherPetsChanged: (v) => setState(() => _hasOtherPets = v),
                
                // --- AQUI ESTÁ A LIGAÇÃO DO CALENDÁRIO ---
                // Partilhamos a mesma variável '_schedule'. Se o user mudar aqui,
                // muda também na tab de Vet (porque é a mesma pessoa).
                currentSchedule: _schedule, 
                onScheduleChanged: (newSchedule) {
                  setState(() {
                    _schedule = newSchedule;
                  });
                },
              ),
          ],
        ),
      ),
    );
  }
}