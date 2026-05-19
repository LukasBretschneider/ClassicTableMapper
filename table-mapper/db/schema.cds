namespace tablemapper;

entity BaseTable {
    key name                 : String(30);
        description          : String(100);
        applicationComponent : String(30);
        releaseState         : String(30);  // NOT_TO_BE_RELEASED, none
        officialSuccessor    : Association to SuccessorEntity;
        virtual fieldCount   : Integer;
        fields      : Composition of many BaseField on fields.baseTable = $self;
        mappings    : Association to many TableMapping on mappings.baseTable = $self;
}

entity BaseField {
    key baseTable   : Association to BaseTable;
    key name        : String(30);
        description : String(100);
}

entity SuccessorEntity {
    key name                 : String(120);
        description          : String(100);
        applicationComponent : String(30);
        isReleased           : Boolean default false;
        releaseContract      : String(4);   // C0, C1, None
        c1Status             : String(20);  // Key-User, Developer, Both
        virtual fieldCount   : Integer;
        fields      : Composition of many SuccessorField on fields.successorEntity = $self;
        mappings    : Association to many TableMapping on mappings.successorEntity = $self;
}

entity SuccessorField {
    key successorEntity : Association to SuccessorEntity;
    key name            : String(120);
        description     : String(100);
}

entity TableMapping {
    key baseTable       : Association to BaseTable;
    key successorEntity : Association to SuccessorEntity;
    key baseField       : String(30);
    key successorField  : String(120);
}
