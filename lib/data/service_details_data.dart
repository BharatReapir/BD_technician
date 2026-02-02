class ServiceDetailsData {
  static Map<String, Map<String, dynamic>> getServiceDetails() {
    return {
      // SPLIT AC SERVICES
      'Split AC_General Service': {
        'title': 'General Service (Split AC)',
        'included': [
          'Indoor filter & panel cleaning',
          'Cooling coil and blower cleaning',
          'Outdoor condenser basic wash',
          'Gas pressure check',
          'Electrical & wiring inspection',
          'Drain pipe cleaning',
          'Cooling performance test',
        ],
        'notIncluded': [
          'Gas refill / top-up',
          'Major repair / part replacement',
          'Installation / Uninstallation / shifting',
          'Deep dismantle wash',
        ],
        'process': [
          'Complete AC inspection',
          'Indoor & outdoor cleaning',
          'Gas and electrical checking',
          'Drain flushing',
          'Performance testing',
        ],
        'bestFor': 'Regular maintenance & long AC life',
        'duration': '45-60 mins',
      },
      
      'Split AC_Jet Machine Service': {
        'title': 'Jet Machine Service (Split AC)',
        'included': [
          'High-pressure jet cleaning of indoor coil',
          'Deep cleaning of blower and fins',
          'Outdoor condenser jet wash',
          'Drain tray and pipe cleaning',
          'Basic airflow check',
          'Removal of heavy mud and blockage',
        ],
        'notIncluded': [
          'Foam / chemical cleaning',
          'Gas refill / pressure check',
          'Electrical repair',
          'Fault diagnosis',
          'Installation / Uninstallation / shifting',
        ],
        'process': [
          'Basic safety check',
          'Indoor jet washing',
          'Outdoor jet washing',
          'Drain cleaning',
          'Final running test',
        ],
        'bestFor': 'Very dirty AC & blocked airflow',
        'duration': '60-75 mins',
      },
      
      'Split AC_Foam Service': {
        'title': 'Foam Service (Split AC)',
        'included': [
          'Thick foam cleaning of cooling coil',
          'Blower and fins deep cleaning',
          'Anti-fungal and odor removal (foam based)',
          'Filter and panel washing',
          'Light water rinse',
          'Basic airflow & cooling check',
        ],
        'notIncluded': [
          'Jet machine washing',
          'Gas checking / refill',
          'Electrical repair',
          'Outdoor deep wash',
          'Installation / Uninstallation / shifting',
        ],
        'process': [
          'Basic inspection',
          'Foam application on indoor unit',
          'Dirt dissolution time (foam action)',
          'Deep cleaning of parts',
          'Light rinse & drying',
          'Final check',
        ],
        'bestFor': 'Bad smell, fungus & low cooling due to dirt',
        'duration': '75-90 mins',
      },
      
      'Split AC_Spray Service': {
        'title': 'Spray Service (Split AC)',
        'included': [
          'Spray cleaning of cooling coil surface',
          'Filter and panel cleaning',
          'Surface dust removal',
          'Quick deodorizing spray (if required)',
          'Basic ON/OFF test',
        ],
        'notIncluded': [
          'Foam cleaning',
          'Jet washing',
          'Outdoor deep cleaning',
          'Gas / electrical check',
          'Installation / Uninstallation / shifting',
        ],
        'process': [
          'Quick inspection',
          'Spray application',
          'Wipe & surface cleaning',
          'Natural drying',
          'Final running test',
        ],
        'bestFor': 'Light dust, quick refresh & budget users',
        'duration': '30-45 mins',
      },
      
      // WINDOW AC SERVICES
      'Window AC_General Service': {
        'title': 'General Service (Window AC)',
        'included': [
          'Front panel and air filter cleaning',
          'Cooling coil and blower cleaning',
          'Outer body and rear condenser cleaning',
          'Gas pressure check',
          'Electrical & wiring inspection',
          'Drain tray and water outlet cleaning',
          'Cooling performance test',
        ],
        'notIncluded': [
          'Gas refill / top-up',
          'Major repair / part replacement',
          'Installation / Uninstallation / shifting',
          'Full dismantle deep wash',
        ],
        'process': [
          'Complete AC inspection',
          'Panel opening and internal cleaning',
          'Rear condenser wash',
          'Gas and electrical checking',
          'Drain cleaning',
          'Performance testing',
        ],
        'bestFor': 'Regular maintenance & smooth performance',
        'duration': '45-60 mins',
      },
      
      'Window AC_Jet Machine Service': {
        'title': 'Jet Machine Service (Window AC)',
        'included': [
          'High-pressure jet cleaning of cooling coil',
          'Deep jet cleaning of blower and fins',
          'Rear condenser high-pressure wash',
          'Drain tray and outlet flushing',
          'Removal of heavy dust and mud',
          'Basic airflow check',
        ],
        'notIncluded': [
          'Foam / chemical cleaning',
          'Gas refill / pressure check',
          'Electrical repair',
          'Fault diagnosis',
          'Installation / Uninstallation / shifting',
        ],
        'process': [
          'Safety and power check',
          'Panel removal',
          'Indoor and rear side jet washing',
          'Drain flushing',
          'Drying and final test',
        ],
        'bestFor': 'Very dirty AC & blocked airflow',
        'duration': '60-75 mins',
      },
      
      'Window AC_Foam + Jet Service': {
        'title': 'Foam + Jet Service (Window AC)',
        'included': [
          'Thick foam application on cooling coil',
          'Foam cleaning of blower and fins',
          'High-pressure jet rinse after foam',
          'Rear condenser jet wash',
          'Filter and panel cleaning',
          'Anti-fungal and odor removal',
          'Basic cooling and airflow check',
        ],
        'notIncluded': [
          'Gas checking / refill',
          'Electrical repair',
          'Part replacement',
          'Installation / Uninstallation / shifting',
        ],
        'process': [
          'Initial inspection',
          'Foam application on internal parts',
          'Foam reaction time',
          'High-pressure jet rinse',
          'Drying and reassembly',
          'Final performance test',
        ],
        'bestFor': 'Bad smell, fungus & deep internal dirt',
        'duration': '75-90 mins',
      },
      
      'Window AC_Spray + Jet Service': {
        'title': 'Spray + Jet Service (Window AC)',
        'included': [
          'Spray cleaning of cooling coil',
          'Light cleaning of blower and fins',
          'High-pressure jet washing',
          'Rear condenser wash',
          'Filter and panel cleaning',
          'Basic ON/OFF and airflow test',
        ],
        'notIncluded': [
          'Foam cleaning',
          'Gas refill / pressure check',
          'Electrical inspection / repair',
          'Major servicing',
          'Installation / Uninstallation / shifting',
        ],
        'process': [
          'Quick inspection',
          'Spray application on coil',
          'Jet washing of internal and rear parts',
          'Wipe and drying',
          'Final running test',
        ],
        'bestFor': 'Medium dirt & quick deep refresh',
        'duration': '60-75 mins',
      },
      
      // INSTALLATION SERVICES
      'Split AC_AC Installation': {
        'title': 'AC Installation (Split AC)',
        'included': [
          'Indoor Unit Wall Mounting',
          'Outdoor Unit Stand / Bracket Installation',
          'Copper Pipe Connection',
          'Drain Pipe Connection',
          'Electrical Wiring Connection',
          'Vacuuming (If Required)',
          'Gas Pressure Check',
          'Final Testing and Cleaning',
        ],
        'notIncluded': [
          'Extra Copper Pipe (charged separately)',
          'Outdoor Unit Stand / Bracket (if not provided)',
          'Additional Wiring (charged separately)',
          'Core Cutting (charged separately)',
          'Masonry work (tiling, cementing, wall repair)',
        ],
        'process': [
          'Site inspection and measurement',
          'Indoor unit mounting',
          'Outdoor unit installation',
          'Pipe and electrical connections',
          'System testing and commissioning',
        ],
        'bestFor': 'New AC installation with professional setup',
        'duration': '2-3 hours',
        'additionalCharges': [
          'Extra Copper Pipe',
          'Outdoor Unit Stand / Bracket',
          'Additional Wiring',
          'Core Cutting',
          'Gas Refilling (If Required)',
        ],
        'importantNotes': [
          'Provide a ladder, if required',
          'Extra wiring will be charged separately',
          'If spare parts are needed, technician will source from local market',
          'Masonry work is not included',
          'Core cutting charges may apply',
        ],
      },
      
      'Window AC_AC Installation': {
        'title': 'AC Installation (Window AC)',
        'included': [
          'Window / Wall Frame Adjustment',
          'Proper Unit Fitting',
          'Drain Pipe Setup',
          'Electrical Wiring Connection',
          'Final Testing',
        ],
        'notIncluded': [
          'Additional Wiring (charged separately)',
          'Frame modification (major)',
          'Masonry work',
        ],
        'process': [
          'Window/wall measurement',
          'Frame preparation',
          'Unit installation and fitting',
          'Electrical connections',
          'Testing and commissioning',
        ],
        'bestFor': 'New window AC installation',
        'duration': '1-2 hours',
        'importantNotes': [
          'Provide a ladder, if required',
          'Extra wiring will be charged separately',
          'Frame modification charges may apply',
        ],
      },
      
      // UNINSTALLATION SERVICES
      'Split AC_AC Uninstallation': {
        'title': 'AC Uninstallation (Split AC)',
        'included': [
          'Safe Removal of Indoor Unit',
          'Safe Removal of Outdoor Unit',
          'Gas Recovery (If Possible)',
          'Copper Pipe Disconnection',
          'Electrical Wiring Disconnection',
          'Packing Support',
        ],
        'notIncluded': [
          'Transportation of unit',
          'Wall repair after removal',
          'Disposal of old unit',
        ],
        'process': [
          'Gas recovery procedure',
          'Safe disconnection of all connections',
          'Careful removal of units',
          'Packing for transportation',
        ],
        'bestFor': 'Safe removal and relocation of AC',
        'duration': '1-2 hours',
        'importantNotes': [
          'Provide a ladder, if required',
          'Gas recovery depends on AC condition',
          'Wall repair is not included',
        ],
      },
      
      'Window AC_AC Uninstallation': {
        'title': 'AC Uninstallation (Window AC)',
        'included': [
          'Safe Removal of Window AC Unit',
          'Frame Adjustment (If Required)',
          'Electrical Wiring Disconnection',
          'Packing Support',
        ],
        'notIncluded': [
          'Transportation of unit',
          'Window repair after removal',
          'Disposal of old unit',
        ],
        'process': [
          'Safe disconnection of electrical connections',
          'Careful removal from window/wall',
          'Frame adjustment if needed',
          'Packing for transportation',
        ],
        'bestFor': 'Safe removal of window AC',
        'duration': '30-60 mins',
        'importantNotes': [
          'Provide a ladder, if required',
          'Frame adjustment depends on installation type',
          'Window repair is not included',
        ],
      },
    };
  }
  
  static Map<String, dynamic>? getServiceDetail(String acType, String serviceName) {
    final key = '${acType}_$serviceName';
    return getServiceDetails()[key];
  }
}