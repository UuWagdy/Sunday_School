import 'package:drift/drift.dart';

@DataClassName('AbsentPerson')
class AbsentPersons extends Table {
  @override
  String get tableName => 'Absent_Persons';
  IntColumn get id => integer().nullable().named('ID')();
  IntColumn get personId => integer().nullable().named('Person_ID')();
  TextColumn get personName => text().nullable().named('Person_Name')();
  TextColumn get stage => text().nullable().named('Stage')();
  TextColumn get month1 => text().nullable().named('Month_1')();
  TextColumn get first => text().nullable().named('First')();
  TextColumn get second => text().nullable().named('second')();
  TextColumn get third => text().nullable().named('third')();
  TextColumn get forth => text().nullable().named('Forth')();
  TextColumn get fife => text().nullable().named('fife')();
}

@DataClassName('AbsentPrintData')
class AbsentPrint extends Table {
  @override
  String get tableName => 'Absent_Print';
  IntColumn get id => integer().nullable().named('ID')();
  IntColumn get personId => integer().nullable().named('Person_ID')();
  TextColumn get personName => text().nullable().named('Person_Name')();
  IntColumn get stageId => integer().nullable().named('Stage_ID')();
  TextColumn get stageName => text().nullable().named('Stage_Name')();
  IntColumn get khorosId => integer().nullable().named('Khoros_ID')();
  TextColumn get khorosName => text().nullable().named('Khoros_Name')();
  IntColumn get areaId => integer().nullable().named('Area_ID')();
  TextColumn get areaName => text().nullable().named('Area_Name')();
  TextColumn get streetName => text().nullable().named('Street_Name')();
  TextColumn get phone => text().nullable().named('Phone')();
  TextColumn get mobile => text().nullable().named('Mobile')();
  TextColumn get dateFrom => text().nullable().named('Date_From')();
  TextColumn get dateTo => text().nullable().named('Date_To')();
}

@DataClassName('AddingData')
class Adding extends Table {
  @override
  String get tableName => 'Adding';
  IntColumn get dateId => integer().nullable().named('Date_ID')();
  TextColumn get date => text().nullable().named('Date')();
}

class Areas extends Table {
  @override
  String get tableName => 'Areas';
  IntColumn get areaId => integer().autoIncrement().named('Area_ID')();
  TextColumn get areaName => text().nullable().named('Area_Name')();
  IntColumn get parentId => integer().nullable().named('Parent_ID')();
  IntColumn get level =>
      integer().withDefault(const Constant(0)).named('Level')();
  TextColumn get areaPath => text().nullable().named('Area_Path')();
}

@DataClassName('ComingData')
class Coming extends Table {
  @override
  String get tableName => 'Coming';
  IntColumn get id => integer().nullable().named('Id')();
  IntColumn get personId => integer().nullable().named('Person_ID')();
  TextColumn get dateWeek => text().nullable().named('date_Week')();
  IntColumn get point => integer().nullable().named('Point')();
  IntColumn get mont1 => integer().nullable().named('Mont_1')();
  IntColumn get year1 => integer().nullable().named('Year_1')();
  IntColumn get serviceId => integer().nullable().named('Service_ID')();
  TextColumn get attendTime => text().nullable().named('Attend_Time')();
  TextColumn get checkoutTime => text().nullable().named('Checkout_Time')();
  IntColumn get visited => integer().nullable().named('Visited')();
  TextColumn get visitNotes => text().nullable().named('Visit_Notes')();
  IntColumn get behavior =>
      integer().nullable().withDefault(const Constant(5)).named('Behavior')();
}

@DataClassName('VisitationData')
class Visitations extends Table {
  @override
  String get tableName => 'Visitations';

  IntColumn get id => integer().autoIncrement().named('ID')();
  IntColumn get personId => integer()
      .named('Person_ID')
      .references(Persons, #personId, onDelete: KeyAction.cascade)();
  IntColumn get serviceId => integer()
      .nullable()
      .named('Service_ID')
      .references(Services, #serviceId, onDelete: KeyAction.setNull)();
  TextColumn get visitDate => text().named('Visit_Date')();
  BoolColumn get isVisited =>
      boolean().withDefault(const Constant(false)).named('Is_Visited')();
  TextColumn get visitType =>
      text().withDefault(const Constant('تليفون')).named('Visit_Type')();
  TextColumn get notes => text().nullable().named('Notes')();
  DateTimeColumn get createdAt =>
      dateTime().withDefault(currentDateAndTime).named('Created_At')();
  DateTimeColumn get updatedAt =>
      dateTime().withDefault(currentDateAndTime).named('Updated_At')();
}

@DataClassName('ServiceData')
class Services extends Table {
  @override
  String get tableName => 'Services';
  IntColumn get serviceId => integer().autoIncrement().named('Service_ID')();
  TextColumn get serviceName => text().nullable().named('Service_Name')();
  IntColumn get dayOfWeek => integer().nullable().named('Day_Of_Week')();
  IntColumn get hour => integer().nullable().named('Hour')();
  IntColumn get minute => integer().nullable().named('Minute')();
  IntColumn get endHour => integer().nullable().named('End_Hour')();
  IntColumn get endMinute => integer().nullable().named('End_Minute')();
  BlobColumn get logo => blob().nullable().named('Logo')();
}

@DataClassName('CreditData')
class Credit extends Table {
  @override
  String get tableName => 'Credit';
  IntColumn get id => integer().nullable().named('Id')();
  IntColumn get personId => integer().nullable().named('Person_ID')();
  TextColumn get personName => text().nullable().named('Person_Name')();
  TextColumn get stageName => text().nullable().named('Stage_Name')();
  TextColumn get areaName => text().nullable().named('Area_name')();
  TextColumn get street => text().nullable().named('Street')();
  TextColumn get phone => text().nullable().named('Phone')();
  TextColumn get mobile => text().nullable().named('Mobile')();
  IntColumn get day => integer().nullable().named('Day')();
  IntColumn get month => integer().nullable().named('month')();
  IntColumn get year => integer().nullable().named('year')();
  TextColumn get jender => text().nullable().named('Jender')();
  BlobColumn get photo => blob().nullable().named('Photo')();
  BlobColumn get parcode => blob().nullable().named('Parcode')();
}

class Fathers extends Table {
  @override
  String get tableName => 'Fathers';
  IntColumn get fatherId => integer().autoIncrement().named('Father_ID')();
  TextColumn get fatherName => text().nullable().named('Father_Name')();
}

@DataClassName('JenderData')
class Jender extends Table {
  @override
  String get tableName => 'Jender';
  IntColumn get jenderId => integer().nullable().named('Jender_ID')();
  TextColumn get jenderName => text().nullable().named('Jender_Name')();
}

@DataClassName('PassData')
class Pass extends Table {
  @override
  String get tableName => 'Pass';
  IntColumn get passId => integer().autoIncrement().named('Pass_ID')();
  TextColumn get passWord => text().nullable().named('Pass_Word')();
  TextColumn get personName => text().nullable().named('Person_Name')();

  // Permissions
  BoolColumn get canPersons => boolean().nullable().named('can_persons')();
  BoolColumn get canStages => boolean().nullable().named('can_stages')();
  BoolColumn get canAreas => boolean().nullable().named('can_areas')();
  BoolColumn get canFathers => boolean().nullable().named('can_fathers')();
  BoolColumn get canReports => boolean().nullable().named('can_reports')();
  BoolColumn get canUsers => boolean().nullable().named('can_users')();
  BoolColumn get canAbsence => boolean().nullable().named('can_absence')();
  BoolColumn get canMaintenance =>
      boolean().nullable().named('can_maintenance')();
  BoolColumn get canIdCard => boolean().nullable().named('can_id_card')();
  BoolColumn get canTayo => boolean().nullable().named('can_tayo')();
  BoolColumn get canTransfer => boolean().nullable().named('can_transfer')();
  BoolColumn get canServices => boolean().nullable().named('can_services')();
  BoolColumn get canKhoros => boolean().nullable().named('can_khoros')();
  BoolColumn get canBehavior => boolean().nullable().named('can_behavior')();
  BoolColumn get isAdvanced =>
      boolean().withDefault(const Constant(false)).named('is_advanced')();
}

class PersonServices extends Table {
  @override
  String get tableName => 'Person_Services';
  IntColumn get personId => integer()
      .named('Person_ID')
      .references(Persons, #personId, onDelete: KeyAction.cascade)();
  IntColumn get serviceId => integer()
      .named('Service_ID')
      .references(Services, #serviceId, onDelete: KeyAction.cascade)();

  @override
  Set<Column> get primaryKey => {personId, serviceId};
}

class KhorosServices extends Table {
  @override
  String get tableName => 'Khoros_Services';
  IntColumn get khorosId => integer()
      .named('Khoros_ID')
      .references(Khoroses, #khorosId, onDelete: KeyAction.cascade)();
  IntColumn get serviceId => integer()
      .named('Service_ID')
      .references(Services, #serviceId, onDelete: KeyAction.cascade)();

  @override
  Set<Column> get primaryKey => {khorosId, serviceId};
}

class StageServices extends Table {
  @override
  String get tableName => 'Stage_Services';
  IntColumn get stageId => integer()
      .named('Stage_ID')
      .references(Stages, #stageId, onDelete: KeyAction.cascade)();
  IntColumn get serviceId => integer()
      .named('Service_ID')
      .references(Services, #serviceId, onDelete: KeyAction.cascade)();

  @override
  Set<Column> get primaryKey => {stageId, serviceId};
}

class UserPermissionsExt extends Table {
  @override
  String get tableName => 'User_Permissions_Ext';
  IntColumn get userId => integer()
      .named('User_ID')
      .references(Pass, #passId, onDelete: KeyAction.cascade)();
  TextColumn get featureKey =>
      text().named('Feature_Key')(); // e.g., 'persons', 'reports'
  BoolColumn get canAdd =>
      boolean().withDefault(const Constant(false)).named('can_add')();
  BoolColumn get canEdit =>
      boolean().withDefault(const Constant(false)).named('can_edit')();
  BoolColumn get canDelete =>
      boolean().withDefault(const Constant(false)).named('can_delete')();

  @override
  Set<Column> get primaryKey => {userId, featureKey};
}

class UserVisibilityFilters extends Table {
  @override
  String get tableName => 'User_Visibility_Filters';
  IntColumn get userId => integer()
      .named('User_ID')
      .references(Pass, #passId, onDelete: KeyAction.cascade)();
  TextColumn get filterType => text().named(
    'Filter_Type',
  )(); // e.g., 'stage', 'service', 'khoros', 'area', 'father'
  IntColumn get valueId => integer().named('Value_ID')();

  @override
  Set<Column> get primaryKey => {userId, filterType, valueId};
}

class Persons extends Table {
  @override
  String get tableName => 'Persons';
  IntColumn get personId => integer().autoIncrement().named('Person_ID')();
  TextColumn get personName => text().nullable().named('Person_Name')();
  IntColumn get stageId => integer().nullable().named('Stage_ID')();
  IntColumn get khorosId => integer().nullable().named('Khoros_ID')();
  IntColumn get areaId => integer().nullable().named('Area_ID')();
  TextColumn get streetName => text().nullable().named('Street_Name')();
  TextColumn get phone => text().nullable().named('Phone')();
  TextColumn get mobile => text().nullable().named('Mobile')();
  IntColumn get day => integer().nullable().named('Day')();
  IntColumn get month => integer().nullable().named('Month')();
  IntColumn get year => integer().nullable().named('Year')();
  TextColumn get jenderName => text().nullable().named('Jender_Name')();
  IntColumn get fatherId => integer().nullable().named('Father_ID')();
  BlobColumn get photo => blob().nullable().named('Photo')();
  TextColumn get rohot => text().nullable().named('Rohot')();
  TextColumn get leader => text().nullable().named('Leader')();
}

class Stages extends Table {
  @override
  String get tableName => 'Stages';
  IntColumn get stageId => integer().autoIncrement().named('Stage_ID')();
  TextColumn get stageName => text().nullable().named('Stage_Name')();
  IntColumn get serviceId => integer()
      .nullable()
      .named('Service_ID')
      .references(Services, #serviceId, onDelete: KeyAction.setNull)();
  IntColumn get nextStageId => integer()
      .nullable()
      .named('Next_Stage_ID')
      .references(Stages, #stageId, onDelete: KeyAction.setNull)();
}

class Khoroses extends Table {
  @override
  String get tableName => 'Khoroses';
  IntColumn get khorosId => integer().autoIncrement().named('Khoros_ID')();
  TextColumn get khorosName => text().nullable().named('Khoros_Name')();
  BlobColumn get logo => blob().nullable().named('Logo')();
  IntColumn get serviceId => integer()
      .nullable()
      .named('Service_ID')
      .references(Services, #serviceId, onDelete: KeyAction.setNull)();
}

class Settings extends Table {
  @override
  String get tableName => 'Settings';
  TextColumn get settingKey => text().named('Setting_Key')();
  TextColumn get settingValue => text().nullable().named('Setting_Value')();

  @override
  Set<Column> get primaryKey => {settingKey};
}

@DataClassName('TayoCard')
class TayoCards extends Table {
  @override
  String get tableName => 'Tayo_Cards';
  IntColumn get cardId => integer().autoIncrement().named('Card_ID')();
  TextColumn get cardName => text().nullable().named('Card_Name')();
  IntColumn get cardPoints => integer().nullable().named('Card_Points')();
  BlobColumn get cardImage => blob().nullable().named('Card_Image')();
}

@DataClassName('PersonTayoPoint')
class PersonTayoPoints extends Table {
  @override
  String get tableName => 'Person_Tayo_Points';
  IntColumn get id => integer().autoIncrement().named('ID')();
  IntColumn get personId => integer().nullable().named('Person_ID')();
  IntColumn get cardId => integer().nullable().named('Card_ID')();
  IntColumn get points => integer().nullable().named('Points')();
  TextColumn get awardDate => text().nullable().named('Award_Date')();
  BoolColumn get isAttendance => boolean().nullable().named('Is_Attendance')();
  TextColumn get notes => text().nullable().named('Notes')();
  IntColumn get serviceId => integer().nullable().named('Service_ID')();
}

@DataClassName('CustomFieldDefinition')
class CustomFieldDefinitions extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get fieldKey => text().unique().nullable().named(
    'Field_Key',
  )(); // null for custom, or 'stage' etc.
  TextColumn get name => text().named('Name')();
  TextColumn get type =>
      text().named('Type')(); // 'text', 'dropdown', 'multi_select', 'native'
  TextColumn get options => text().nullable().named('Options')(); // JSON array
  IntColumn get fieldOrder => integer().named('Field_Order')();
  BoolColumn get isVisible =>
      boolean().withDefault(const Constant(true)).named('Is_Visible')();
  BoolColumn get isFilter =>
      boolean().withDefault(const Constant(false)).named('Is_Filter')();
  BoolColumn get isPhone =>
      boolean().withDefault(const Constant(false)).named('Is_Phone')();
}

@DataClassName('PersonCustomFieldValue')
class PersonCustomFieldValues extends Table {
  IntColumn get personId => integer()
      .named('Person_ID')
      .references(Persons, #personId, onDelete: KeyAction.cascade)();
  IntColumn get fieldId => integer()
      .named('Field_ID')
      .references(CustomFieldDefinitions, #id, onDelete: KeyAction.cascade)();
  TextColumn get value => text().nullable().named('Value')();

  @override
  Set<Column> get primaryKey => {personId, fieldId};
}

class PersonDocuments extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get personId => integer()
      .named('Person_ID')
      .references(Persons, #personId, onDelete: KeyAction.cascade)();
  IntColumn get fieldId => integer()
      .named('Field_ID')
      .references(CustomFieldDefinitions, #id, onDelete: KeyAction.cascade)();
  TextColumn get fileName => text().named('File_Name')();
  BlobColumn get fileContent => blob().named('File_Content')();
  DateTimeColumn get createdAt =>
      dateTime().withDefault(currentDateAndTime).named('Created_At')();
}

class FamilyRelationships extends Table {
  @override
  String get tableName => 'Family_Relationships';

  IntColumn get id => integer().autoIncrement().named('ID')();
  @ReferenceName('personRelationships')
  IntColumn get personId => integer()
      .named('Person_ID')
      .references(Persons, #personId, onDelete: KeyAction.cascade)();

  @ReferenceName('relatedPersonRelationships')
  IntColumn get relatedPersonId => integer()
      .named('Related_Person_ID')
      .references(Persons, #personId, onDelete: KeyAction.cascade)();

  // categories: marriage, first_degree, second_degree, third_degree, other
  TextColumn get category => text().named('Category')();

  // codes: FATHER, MOTHER, SON, DAUGHTER, HUSBAND, WIFE, BROTHER, SISTER, UNCLE_PATERNAL, etc.
  TextColumn get relationshipCode => text().named('Relationship_Code')();

  TextColumn get customLabel => text().nullable().named('Custom_Label')();

  DateTimeColumn get createdAt =>
      dateTime().withDefault(currentDateAndTime).named('Created_At')();
}
