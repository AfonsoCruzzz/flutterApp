class VeterinaryData {
  // Animais que o vet trata
  static const List<String> speciesList = [
    'Cães', 'Gatos', 'Exóticos', 'Equinos', 'Animais de Quinta', 'Aves'
  ];

  // Especialidades (o "Título" do médico)
  static const List<String> specialtiesList = [
    'Clínica Geral', 'Cirurgia', 'Dermatologia', 'Ortopedia', 
    'Oftalmologia', 'Cardiologia', 'Comportamento', 'Fisioterapia', 
    'Odontologia', 'Oncologia', 'Nutrição'
  ];

  // Serviços: Aqui separamos logicamente o que exige clínica
  static const List<String> basicServices = [
    'Consulta Geral', 'Vacinação', 'Desparasitação', 
    'Microchip', 'Penso / Curativo', 'Eutanásia', 
    'Teleconsulta', 'Análises Clínicas (Recolha)'
  ];

  static const List<String> clinicOnlyServices = [
    'Cirurgia Geral', 'Esterilização', 'Raio-X', 
    'Ecografia', 'Internamento', 'Limpeza de Dentes', 
    'Urgência Cirúrgica'
  ];

  // Função auxiliar para saber o que mostrar
  static List<String> getAvailableServices(String serviceType) {
    if (serviceType == 'independent') {
      // Se for só independente (assumindo domicílio), só mostra serviços básicos
      return basicServices;
    } 
    // Se for Clínica ou Both, mostra tudo
    return [...basicServices, ...clinicOnlyServices];
  }
}