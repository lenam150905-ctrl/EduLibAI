SELECT
    CONNECTIONPROPERTY('local_net_address') AS LocalAddress,
    CONNECTIONPROPERTY('local_tcp_port') AS TCPPort;
	SELECT
    @@SERVERNAME AS ServerName,
    SERVERPROPERTY('InstanceName') AS InstanceName;
/*
    EduLib AI - Database v1
    SQL Server
    Scope: MVP - 28 tables
    Naming: English table/column names, Code has 2-letter prefix + 6 digits.
    Internal PK/FK uses BIGINT for efficient joins.
*/

IF DB_ID(N'EduLibAI') IS NULL
BEGIN
    CREATE DATABASE EduLibAI;
END
GO

USE EduLibAI;
GO

/* =========================================================
   1. CORE
   ========================================================= */

CREATE TABLE dbo.School
(
    SchoolId        BIGINT IDENTITY(1,1) NOT NULL,
    SchoolCode      VARCHAR(8) NULL,
    SchoolName      NVARCHAR(200) NOT NULL,
    Address         NVARCHAR(300) NULL,
    Email           VARCHAR(100) NULL,
    Phone           VARCHAR(20) NULL,
    IsActive        BIT NOT NULL CONSTRAINT DF_School_IsActive DEFAULT (1),
    CreatedAt       DATETIME2(0) NOT NULL CONSTRAINT DF_School_CreatedAt DEFAULT (SYSDATETIME()),
    UpdatedAt       DATETIME2(0) NULL,

    CONSTRAINT PK_School PRIMARY KEY (SchoolId),
    CONSTRAINT UQ_School_SchoolCode UNIQUE (SchoolCode),
    CONSTRAINT CK_School_SchoolCode CHECK (SchoolCode LIKE 'SC[0-9][0-9][0-9][0-9][0-9][0-9]'),
    CONSTRAINT CK_School_Email CHECK (Email IS NULL OR Email LIKE '%_@_%._%')
);
GO

CREATE TABLE dbo.[User]
(
    UserId          BIGINT IDENTITY(1,1) NOT NULL,
    UserCode        VARCHAR(8) NULL,
    SchoolId        BIGINT NULL,
    Username        VARCHAR(30) NOT NULL,
    Email           VARCHAR(100) NULL,
    PasswordHash    VARCHAR(255) NOT NULL,
    FullName        NVARCHAR(25) NOT NULL,
    AvatarUrl       VARCHAR(500) NULL,
    IsActive        BIT NOT NULL CONSTRAINT DF_User_IsActive DEFAULT (1),
    CreatedAt       DATETIME2(0) NOT NULL CONSTRAINT DF_User_CreatedAt DEFAULT (SYSDATETIME()),
    UpdatedAt       DATETIME2(0) NULL,
    LastLoginAt     DATETIME2(0) NULL,

    CONSTRAINT PK_User PRIMARY KEY (UserId),
    CONSTRAINT UQ_User_UserCode UNIQUE (UserCode),
    CONSTRAINT UQ_User_Username UNIQUE (Username),
    CONSTRAINT UQ_User_Email UNIQUE (Email),
    CONSTRAINT CK_User_UserCode CHECK (UserCode LIKE 'US[0-9][0-9][0-9][0-9][0-9][0-9]'),
    CONSTRAINT CK_User_Email CHECK (Email IS NULL OR Email LIKE '%_@_%._%'),
    CONSTRAINT FK_User_School FOREIGN KEY (SchoolId) REFERENCES dbo.School(SchoolId)
);
GO

CREATE TABLE dbo.Role
(
    RoleId          BIGINT IDENTITY(1,1) NOT NULL,
    RoleCode        VARCHAR(30) NOT NULL,
    RoleName        NVARCHAR(100) NOT NULL,
    Description     NVARCHAR(500) NULL,

    CONSTRAINT PK_Role PRIMARY KEY (RoleId),
    CONSTRAINT UQ_Role_RoleCode UNIQUE (RoleCode)
);
GO

CREATE TABLE dbo.Permission
(
    PermissionId    BIGINT IDENTITY(1,1) NOT NULL,
    PermissionCode  VARCHAR(50) NOT NULL,
    PermissionName  NVARCHAR(100) NOT NULL,
    Description     NVARCHAR(500) NULL,

    CONSTRAINT PK_Permission PRIMARY KEY (PermissionId),
    CONSTRAINT UQ_Permission_Code UNIQUE (PermissionCode)
);
GO

CREATE TABLE dbo.UserRole
(
    UserId          BIGINT NOT NULL,
    RoleId          BIGINT NOT NULL,

    CONSTRAINT PK_UserRole PRIMARY KEY (UserId, RoleId),
    CONSTRAINT FK_UserRole_User FOREIGN KEY (UserId) REFERENCES dbo.[User](UserId) ON DELETE CASCADE,
    CONSTRAINT FK_UserRole_Role FOREIGN KEY (RoleId) REFERENCES dbo.Role(RoleId) ON DELETE CASCADE
);
GO

CREATE TABLE dbo.RolePermission
(
    RoleId          BIGINT NOT NULL,
    PermissionId    BIGINT NOT NULL,

    CONSTRAINT PK_RolePermission PRIMARY KEY (RoleId, PermissionId),
    CONSTRAINT FK_RolePermission_Role FOREIGN KEY (RoleId) REFERENCES dbo.Role(RoleId) ON DELETE CASCADE,
    CONSTRAINT FK_RolePermission_Permission FOREIGN KEY (PermissionId) REFERENCES dbo.Permission(PermissionId) ON DELETE CASCADE
);
GO

/* =========================================================
   2. LIBRARY
   ========================================================= */

CREATE TABLE dbo.DocumentType
(
    DocumentTypeId  BIGINT IDENTITY(1,1) NOT NULL,
    TypeCode        VARCHAR(30) NOT NULL,
    TypeName        NVARCHAR(100) NOT NULL,
    Description     NVARCHAR(500) NULL,
    IsActive        BIT NOT NULL CONSTRAINT DF_DocumentType_IsActive DEFAULT (1),

    CONSTRAINT PK_DocumentType PRIMARY KEY (DocumentTypeId),
    CONSTRAINT UQ_DocumentType_TypeCode UNIQUE (TypeCode)
);
GO

CREATE TABLE dbo.Document
(
    DocumentId      BIGINT IDENTITY(1,1) NOT NULL,
    DocumentCode    VARCHAR(8) NULL,
    SchoolId        BIGINT NOT NULL,
    DocumentTypeId  BIGINT NOT NULL,
    Title           NVARCHAR(300) NOT NULL,
    Description     NVARCHAR(MAX) NULL,
    ISBN            VARCHAR(30) NULL,
    Publisher       NVARCHAR(200) NULL,
    PublicationYear SMALLINT NULL,
    LanguageCode    VARCHAR(10) NULL,
    PageCount       INT NULL,
    CoverImageUrl   VARCHAR(500) NULL,
    OwnerUserId     BIGINT NOT NULL,
    Status          VARCHAR(20) NOT NULL CONSTRAINT DF_Document_Status DEFAULT ('ACTIVE'),
    Visibility      VARCHAR(20) NOT NULL CONSTRAINT DF_Document_Visibility DEFAULT ('SCHOOL'),
    CreatedAt       DATETIME2(0) NOT NULL CONSTRAINT DF_Document_CreatedAt DEFAULT (SYSDATETIME()),
    UpdatedAt       DATETIME2(0) NULL,

    CONSTRAINT PK_Document PRIMARY KEY (DocumentId),
    CONSTRAINT UQ_Document_DocumentCode UNIQUE (DocumentCode),
    CONSTRAINT CK_Document_DocumentCode CHECK (DocumentCode LIKE 'DO[0-9][0-9][0-9][0-9][0-9][0-9]'),
    CONSTRAINT CK_Document_Status CHECK (Status IN ('DRAFT','PROCESSING','ACTIVE','INACTIVE','ARCHIVED')),
    CONSTRAINT CK_Document_Visibility CHECK (Visibility IN ('PRIVATE','SCHOOL','SHARED','PUBLIC')),
    CONSTRAINT CK_Document_PublicationYear CHECK (PublicationYear IS NULL OR PublicationYear BETWEEN 1000 AND 9999),
    CONSTRAINT CK_Document_PageCount CHECK (PageCount IS NULL OR PageCount >= 0),
    CONSTRAINT FK_Document_School FOREIGN KEY (SchoolId) REFERENCES dbo.School(SchoolId),
    CONSTRAINT FK_Document_Type FOREIGN KEY (DocumentTypeId) REFERENCES dbo.DocumentType(DocumentTypeId),
    CONSTRAINT FK_Document_Owner FOREIGN KEY (OwnerUserId) REFERENCES dbo.[User](UserId)
);
GO

CREATE TABLE dbo.Author
(
    AuthorId        BIGINT IDENTITY(1,1) NOT NULL,
    AuthorCode      VARCHAR(8) NULL,
    FullName        NVARCHAR(150) NOT NULL,
    Biography       NVARCHAR(MAX) NULL,

    CONSTRAINT PK_Author PRIMARY KEY (AuthorId),
    CONSTRAINT UQ_Author_AuthorCode UNIQUE (AuthorCode),
    CONSTRAINT CK_Author_AuthorCode CHECK (AuthorCode LIKE 'AU[0-9][0-9][0-9][0-9][0-9][0-9]')
);
GO

CREATE TABLE dbo.DocumentAuthor
(
    DocumentId      BIGINT NOT NULL,
    AuthorId        BIGINT NOT NULL,
    AuthorOrder     INT NOT NULL CONSTRAINT DF_DocumentAuthor_AuthorOrder DEFAULT (1),

    CONSTRAINT PK_DocumentAuthor PRIMARY KEY (DocumentId, AuthorId),
    CONSTRAINT CK_DocumentAuthor_AuthorOrder CHECK (AuthorOrder > 0),
    CONSTRAINT FK_DocumentAuthor_Document FOREIGN KEY (DocumentId) REFERENCES dbo.Document(DocumentId) ON DELETE CASCADE,
    CONSTRAINT FK_DocumentAuthor_Author FOREIGN KEY (AuthorId) REFERENCES dbo.Author(AuthorId)
);
GO

CREATE TABLE dbo.Category
(
    CategoryId      BIGINT IDENTITY(1,1) NOT NULL,
    CategoryCode    VARCHAR(8) NULL,
    SchoolId        BIGINT NULL,
    ParentCategoryId BIGINT NULL,
    CategoryName    NVARCHAR(150) NOT NULL,
    Description     NVARCHAR(500) NULL,
    IsActive        BIT NOT NULL CONSTRAINT DF_Category_IsActive DEFAULT (1),

    CONSTRAINT PK_Category PRIMARY KEY (CategoryId),
    CONSTRAINT UQ_Category_CategoryCode UNIQUE (CategoryCode),
    CONSTRAINT CK_Category_CategoryCode CHECK (CategoryCode LIKE 'CA[0-9][0-9][0-9][0-9][0-9][0-9]'),
    CONSTRAINT FK_Category_School FOREIGN KEY (SchoolId) REFERENCES dbo.School(SchoolId),
    CONSTRAINT FK_Category_Parent FOREIGN KEY (ParentCategoryId) REFERENCES dbo.Category(CategoryId)
);
GO

CREATE TABLE dbo.Tag
(
    TagId           BIGINT IDENTITY(1,1) NOT NULL,
    TagCode         VARCHAR(8) NULL,
    SchoolId        BIGINT NULL,
    TagName         NVARCHAR(100) NOT NULL,

    CONSTRAINT PK_Tag PRIMARY KEY (TagId),
    CONSTRAINT UQ_Tag_TagCode UNIQUE (TagCode),
    CONSTRAINT CK_Tag_TagCode CHECK (TagCode LIKE 'TG[0-9][0-9][0-9][0-9][0-9][0-9]'),
    CONSTRAINT FK_Tag_School FOREIGN KEY (SchoolId) REFERENCES dbo.School(SchoolId)
);
GO

CREATE TABLE dbo.DocumentTag
(
    DocumentId      BIGINT NOT NULL,
    TagId           BIGINT NOT NULL,

    CONSTRAINT PK_DocumentTag PRIMARY KEY (DocumentId, TagId),
    CONSTRAINT FK_DocumentTag_Document FOREIGN KEY (DocumentId) REFERENCES dbo.Document(DocumentId) ON DELETE CASCADE,
    CONSTRAINT FK_DocumentTag_Tag FOREIGN KEY (TagId) REFERENCES dbo.Tag(TagId)
);
GO

CREATE TABLE dbo.DocumentFile
(
    DocumentFileId  BIGINT IDENTITY(1,1) NOT NULL,
    DocumentId      BIGINT NOT NULL,
    FileName        NVARCHAR(255) NOT NULL,
    StorageKey      VARCHAR(500) NOT NULL,
    FileExtension   VARCHAR(20) NOT NULL,
    MimeType        VARCHAR(100) NULL,
    FileSizeBytes   BIGINT NULL,
    Checksum        VARCHAR(128) NULL,
    UploadedBy      BIGINT NOT NULL,
    UploadedAt      DATETIME2(0) NOT NULL CONSTRAINT DF_DocumentFile_UploadedAt DEFAULT (SYSDATETIME()),
    IsActive        BIT NOT NULL CONSTRAINT DF_DocumentFile_IsActive DEFAULT (1),

    CONSTRAINT PK_DocumentFile PRIMARY KEY (DocumentFileId),
    CONSTRAINT FK_DocumentFile_Document FOREIGN KEY (DocumentId) REFERENCES dbo.Document(DocumentId) ON DELETE CASCADE,
    CONSTRAINT FK_DocumentFile_User FOREIGN KEY (UploadedBy) REFERENCES dbo.[User](UserId),
    CONSTRAINT CK_DocumentFile_FileSize CHECK (FileSizeBytes IS NULL OR FileSizeBytes >= 0)
);
GO

/* =========================================================
   3. ACCESS / LICENSE
   ========================================================= */

CREATE TABLE dbo.License
(
    LicenseId       BIGINT IDENTITY(1,1) NOT NULL,
    LicenseCode     VARCHAR(30) NOT NULL,
    LicenseName     NVARCHAR(100) NOT NULL,
    LicenseType     VARCHAR(30) NOT NULL,
    Description     NVARCHAR(500) NULL,
    CanView         BIT NOT NULL CONSTRAINT DF_License_CanView DEFAULT (1),
    CanDownload     BIT NOT NULL CONSTRAINT DF_License_CanDownload DEFAULT (0),
    CanShare        BIT NOT NULL CONSTRAINT DF_License_CanShare DEFAULT (0),
    CanUseForRAG    BIT NOT NULL CONSTRAINT DF_License_CanUseForRAG DEFAULT (0),
    IsActive        BIT NOT NULL CONSTRAINT DF_License_IsActive DEFAULT (1),

    CONSTRAINT PK_License PRIMARY KEY (LicenseId),
    CONSTRAINT UQ_License_Code UNIQUE (LicenseCode)
);
GO

CREATE TABLE dbo.DocumentAccess
(
    DocumentAccessId BIGINT IDENTITY(1,1) NOT NULL,
    DocumentId       BIGINT NOT NULL,
    SchoolId         BIGINT NULL,
    UserId           BIGINT NULL,
    LicenseId        BIGINT NULL,
    AccessType       VARCHAR(30) NOT NULL,
    GrantedBy        BIGINT NOT NULL,
    GrantedAt        DATETIME2(0) NOT NULL CONSTRAINT DF_DocumentAccess_GrantedAt DEFAULT (SYSDATETIME()),
    ExpiredAt        DATETIME2(0) NULL,
    IsActive         BIT NOT NULL CONSTRAINT DF_DocumentAccess_IsActive DEFAULT (1),

    CONSTRAINT PK_DocumentAccess PRIMARY KEY (DocumentAccessId),
    CONSTRAINT CK_DocumentAccess_Target CHECK (SchoolId IS NOT NULL OR UserId IS NOT NULL),
    CONSTRAINT CK_DocumentAccess_AccessType CHECK (AccessType IN ('VIEW','DOWNLOAD','FULL')),
    CONSTRAINT FK_DocumentAccess_Document FOREIGN KEY (DocumentId) REFERENCES dbo.Document(DocumentId) ON DELETE CASCADE,
    CONSTRAINT FK_DocumentAccess_School FOREIGN KEY (SchoolId) REFERENCES dbo.School(SchoolId),
    CONSTRAINT FK_DocumentAccess_User FOREIGN KEY (UserId) REFERENCES dbo.[User](UserId),
    CONSTRAINT FK_DocumentAccess_License FOREIGN KEY (LicenseId) REFERENCES dbo.License(LicenseId),
    CONSTRAINT FK_DocumentAccess_GrantedBy FOREIGN KEY (GrantedBy) REFERENCES dbo.[User](UserId)
);
GO

CREATE TABLE dbo.AccessRequest
(
    AccessRequestId     BIGINT IDENTITY(1,1) NOT NULL,
    DocumentId          BIGINT NOT NULL,
    RequesterSchoolId   BIGINT NOT NULL,
    RequesterUserId     BIGINT NOT NULL,
    OwnerSchoolId       BIGINT NOT NULL,
    Reason              NVARCHAR(1000) NULL,
    Status              VARCHAR(20) NOT NULL CONSTRAINT DF_AccessRequest_Status DEFAULT ('PENDING'),
    ReviewedBy          BIGINT NULL,
    ReviewedAt          DATETIME2(0) NULL,
    CreatedAt           DATETIME2(0) NOT NULL CONSTRAINT DF_AccessRequest_CreatedAt DEFAULT (SYSDATETIME()),

    CONSTRAINT PK_AccessRequest PRIMARY KEY (AccessRequestId),
    CONSTRAINT CK_AccessRequest_Status CHECK (Status IN ('PENDING','APPROVED','REJECTED','CANCELLED')),
    CONSTRAINT FK_AccessRequest_Document FOREIGN KEY (DocumentId) REFERENCES dbo.Document(DocumentId) ON DELETE CASCADE,
    CONSTRAINT FK_AccessRequest_RequesterSchool FOREIGN KEY (RequesterSchoolId) REFERENCES dbo.School(SchoolId),
    CONSTRAINT FK_AccessRequest_RequesterUser FOREIGN KEY (RequesterUserId) REFERENCES dbo.[User](UserId),
    CONSTRAINT FK_AccessRequest_OwnerSchool FOREIGN KEY (OwnerSchoolId) REFERENCES dbo.School(SchoolId),
    CONSTRAINT FK_AccessRequest_Reviewer FOREIGN KEY (ReviewedBy) REFERENCES dbo.[User](UserId)
);
GO

/* =========================================================
   4. USER COLLECTIONS
   ========================================================= */

CREATE TABLE dbo.Collection
(
    CollectionId     BIGINT IDENTITY(1,1) NOT NULL,
    CollectionCode   VARCHAR(8) NULL,
    UserId           BIGINT NOT NULL,
    SchoolId         BIGINT NOT NULL,
    CollectionName   NVARCHAR(150) NOT NULL,
    Description      NVARCHAR(500) NULL,
    IsPublic         BIT NOT NULL CONSTRAINT DF_Collection_IsPublic DEFAULT (0),
    CreatedAt        DATETIME2(0) NOT NULL CONSTRAINT DF_Collection_CreatedAt DEFAULT (SYSDATETIME()),
    UpdatedAt        DATETIME2(0) NULL,

    CONSTRAINT PK_Collection PRIMARY KEY (CollectionId),
    CONSTRAINT UQ_Collection_Code UNIQUE (CollectionCode),
    CONSTRAINT CK_Collection_Code CHECK (CollectionCode LIKE 'CL[0-9][0-9][0-9][0-9][0-9][0-9]'),
    CONSTRAINT FK_Collection_User FOREIGN KEY (UserId) REFERENCES dbo.[User](UserId) ON DELETE CASCADE,
    CONSTRAINT FK_Collection_School FOREIGN KEY (SchoolId) REFERENCES dbo.School(SchoolId)
);
GO

CREATE TABLE dbo.CollectionDocument
(
    CollectionId    BIGINT NOT NULL,
    DocumentId      BIGINT NOT NULL,
    AddedAt         DATETIME2(0) NOT NULL CONSTRAINT DF_CollectionDocument_AddedAt DEFAULT (SYSDATETIME()),

    CONSTRAINT PK_CollectionDocument PRIMARY KEY (CollectionId, DocumentId),
    CONSTRAINT FK_CollectionDocument_Collection FOREIGN KEY (CollectionId) REFERENCES dbo.Collection(CollectionId) ON DELETE CASCADE,
    CONSTRAINT FK_CollectionDocument_Document FOREIGN KEY (DocumentId) REFERENCES dbo.Document(DocumentId) ON DELETE CASCADE
);
GO

CREATE TABLE dbo.Favorite
(
    UserId          BIGINT NOT NULL,
    DocumentId      BIGINT NOT NULL,
    CreatedAt       DATETIME2(0) NOT NULL CONSTRAINT DF_Favorite_CreatedAt DEFAULT (SYSDATETIME()),

    CONSTRAINT PK_Favorite PRIMARY KEY (UserId, DocumentId),
    CONSTRAINT FK_Favorite_User FOREIGN KEY (UserId) REFERENCES dbo.[User](UserId) ON DELETE CASCADE,
    CONSTRAINT FK_Favorite_Document FOREIGN KEY (DocumentId) REFERENCES dbo.Document(DocumentId) ON DELETE CASCADE
);
GO

CREATE TABLE dbo.ReadingHistory
(
    ReadingHistoryId BIGINT IDENTITY(1,1) NOT NULL,
    UserId           BIGINT NOT NULL,
    DocumentId       BIGINT NOT NULL,
    LastPage         INT NULL,
    ProgressPercent  DECIMAL(5,2) NULL,
    LastReadAt       DATETIME2(0) NOT NULL CONSTRAINT DF_ReadingHistory_LastReadAt DEFAULT (SYSDATETIME()),

    CONSTRAINT PK_ReadingHistory PRIMARY KEY (ReadingHistoryId),
    CONSTRAINT UQ_ReadingHistory_UserDocument UNIQUE (UserId, DocumentId),
    CONSTRAINT CK_ReadingHistory_LastPage CHECK (LastPage IS NULL OR LastPage >= 0),
    CONSTRAINT CK_ReadingHistory_Progress CHECK (ProgressPercent IS NULL OR ProgressPercent BETWEEN 0 AND 100),
    CONSTRAINT FK_ReadingHistory_User FOREIGN KEY (UserId) REFERENCES dbo.[User](UserId) ON DELETE CASCADE,
    CONSTRAINT FK_ReadingHistory_Document FOREIGN KEY (DocumentId) REFERENCES dbo.Document(DocumentId) ON DELETE CASCADE
);
GO

CREATE TABLE dbo.DownloadHistory
(
    DownloadHistoryId BIGINT IDENTITY(1,1) NOT NULL,
    UserId            BIGINT NOT NULL,
    DocumentId        BIGINT NOT NULL,
    DocumentFileId    BIGINT NOT NULL,
    DownloadedAt      DATETIME2(0) NOT NULL CONSTRAINT DF_DownloadHistory_DownloadedAt DEFAULT (SYSDATETIME()),

    CONSTRAINT PK_DownloadHistory PRIMARY KEY (DownloadHistoryId),
    CONSTRAINT FK_DownloadHistory_User FOREIGN KEY (UserId) REFERENCES dbo.[User](UserId),
    CONSTRAINT FK_DownloadHistory_Document FOREIGN KEY (DocumentId) REFERENCES dbo.Document(DocumentId),
    CONSTRAINT FK_DownloadHistory_File FOREIGN KEY (DocumentFileId) REFERENCES dbo.DocumentFile(DocumentFileId)
);
GO

/* =========================================================
   5. AI INGESTION
   ========================================================= */

CREATE TABLE dbo.DocumentVersion
(
    DocumentVersionId BIGINT IDENTITY(1,1) NOT NULL,
    DocumentId        BIGINT NOT NULL,
    VersionNumber     INT NOT NULL,
    DocumentFileId    BIGINT NOT NULL,
    ChangeNote        NVARCHAR(500) NULL,
    CreatedBy         BIGINT NOT NULL,
    CreatedAt         DATETIME2(0) NOT NULL CONSTRAINT DF_DocumentVersion_CreatedAt DEFAULT (SYSDATETIME()),
    IsCurrent         BIT NOT NULL CONSTRAINT DF_DocumentVersion_IsCurrent DEFAULT (1),

    CONSTRAINT PK_DocumentVersion PRIMARY KEY (DocumentVersionId),
    CONSTRAINT UQ_DocumentVersion_DocumentVersion UNIQUE (DocumentId, VersionNumber),
    CONSTRAINT CK_DocumentVersion_VersionNumber CHECK (VersionNumber > 0),
    CONSTRAINT FK_DocumentVersion_Document FOREIGN KEY (DocumentId) REFERENCES dbo.Document(DocumentId) ON DELETE CASCADE,
    CONSTRAINT FK_DocumentVersion_File FOREIGN KEY (DocumentFileId) REFERENCES dbo.DocumentFile(DocumentFileId),
    CONSTRAINT FK_DocumentVersion_User FOREIGN KEY (CreatedBy) REFERENCES dbo.[User](UserId)
);
GO

CREATE TABLE dbo.DocumentProcessing
(
    ProcessingId      BIGINT IDENTITY(1,1) NOT NULL,
    DocumentId        BIGINT NOT NULL,
    DocumentVersionId BIGINT NULL,
    Status            VARCHAR(20) NOT NULL CONSTRAINT DF_DocumentProcessing_Status DEFAULT ('PENDING'),
    CurrentStep       VARCHAR(30) NULL,
    ErrorMessage      NVARCHAR(2000) NULL,
    StartedAt         DATETIME2(0) NULL,
    CompletedAt       DATETIME2(0) NULL,
    RetryCount        INT NOT NULL CONSTRAINT DF_DocumentProcessing_RetryCount DEFAULT (0),
    CreatedAt         DATETIME2(0) NOT NULL CONSTRAINT DF_DocumentProcessing_CreatedAt DEFAULT (SYSDATETIME()),

    CONSTRAINT PK_DocumentProcessing PRIMARY KEY (ProcessingId),
    CONSTRAINT CK_DocumentProcessing_Status CHECK (Status IN ('PENDING','PROCESSING','COMPLETED','FAILED')),
    CONSTRAINT CK_DocumentProcessing_Step CHECK (
        CurrentStep IS NULL OR CurrentStep IN ('VALIDATE','EXTRACT','CLEAN','CHUNK','EMBEDDING','INDEX')
    ),
    CONSTRAINT CK_DocumentProcessing_Retry CHECK (RetryCount >= 0),
    CONSTRAINT FK_DocumentProcessing_Document FOREIGN KEY (DocumentId) REFERENCES dbo.Document(DocumentId) ON DELETE CASCADE,
    CONSTRAINT FK_DocumentProcessing_Version FOREIGN KEY (DocumentVersionId) REFERENCES dbo.DocumentVersion(DocumentVersionId)
);
GO

CREATE TABLE dbo.DocumentChunk
(
    ChunkId           BIGINT IDENTITY(1,1) NOT NULL,
    DocumentId        BIGINT NOT NULL,
    DocumentVersionId BIGINT NULL,
    ChunkIndex        INT NOT NULL,
    Content           NVARCHAR(MAX) NOT NULL,
    PageNumber        INT NULL,
    StartPosition     INT NULL,
    EndPosition       INT NULL,
    TokenCount        INT NULL,
    CreatedAt         DATETIME2(0) NOT NULL CONSTRAINT DF_DocumentChunk_CreatedAt DEFAULT (SYSDATETIME()),

    CONSTRAINT PK_DocumentChunk PRIMARY KEY (ChunkId),
    CONSTRAINT UQ_DocumentChunk_Index UNIQUE (DocumentId, DocumentVersionId, ChunkIndex),
    CONSTRAINT CK_DocumentChunk_ChunkIndex CHECK (ChunkIndex >= 0),
    CONSTRAINT CK_DocumentChunk_PageNumber CHECK (PageNumber IS NULL OR PageNumber >= 0),
    CONSTRAINT CK_DocumentChunk_TokenCount CHECK (TokenCount IS NULL OR TokenCount >= 0),
    CONSTRAINT FK_DocumentChunk_Document FOREIGN KEY (DocumentId) REFERENCES dbo.Document(DocumentId) ON DELETE CASCADE,
    CONSTRAINT FK_DocumentChunk_Version FOREIGN KEY (DocumentVersionId) REFERENCES dbo.DocumentVersion(DocumentVersionId)
);
GO

/*
    Vector storage is intentionally kept flexible.
    If the selected SQL Server version supports VECTOR, VectorData can later
    be changed to the native VECTOR type. For now it is stored as VARBINARY(MAX).
*/
CREATE TABLE dbo.Embedding
(
    EmbeddingId       BIGINT IDENTITY(1,1) NOT NULL,
    ChunkId           BIGINT NOT NULL,
    ModelName         VARCHAR(100) NOT NULL,
    Dimension         INT NOT NULL,
    VectorData        VARBINARY(MAX) NOT NULL,
    CreatedAt         DATETIME2(0) NOT NULL CONSTRAINT DF_Embedding_CreatedAt DEFAULT (SYSDATETIME()),

    CONSTRAINT PK_Embedding PRIMARY KEY (EmbeddingId),
    CONSTRAINT UQ_Embedding_Chunk_Model UNIQUE (ChunkId, ModelName),
    CONSTRAINT CK_Embedding_Dimension CHECK (Dimension > 0),
    CONSTRAINT FK_Embedding_Chunk FOREIGN KEY (ChunkId) REFERENCES dbo.DocumentChunk(ChunkId) ON DELETE CASCADE
);
GO

/* =========================================================
   6. RAG
   ========================================================= */

CREATE TABLE dbo.Conversation
(
    ConversationId    BIGINT IDENTITY(1,1) NOT NULL,
    UserId            BIGINT NOT NULL,
    SchoolId          BIGINT NOT NULL,
    Title             NVARCHAR(200) NULL,
    CreatedAt         DATETIME2(0) NOT NULL CONSTRAINT DF_Conversation_CreatedAt DEFAULT (SYSDATETIME()),
    UpdatedAt         DATETIME2(0) NULL,

    CONSTRAINT PK_Conversation PRIMARY KEY (ConversationId),
    CONSTRAINT FK_Conversation_User FOREIGN KEY (UserId) REFERENCES dbo.[User](UserId),
    CONSTRAINT FK_Conversation_School FOREIGN KEY (SchoolId) REFERENCES dbo.School(SchoolId)
);
GO

GO

CREATE TABLE dbo.ConversationMessage
(
    MessageId        BIGINT IDENTITY(1,1) NOT NULL,
    ConversationId   BIGINT NOT NULL,
    Role             VARCHAR(20) NOT NULL,
    Content          NVARCHAR(MAX) NOT NULL,
    CreatedAt        DATETIME2(0) NOT NULL CONSTRAINT DF_ConversationMessage_CreatedAt DEFAULT (SYSDATETIME()),

    CONSTRAINT PK_ConversationMessage PRIMARY KEY (MessageId),
    CONSTRAINT CK_ConversationMessage_Role CHECK (Role IN ('SYSTEM','USER','ASSISTANT')),
    CONSTRAINT FK_ConversationMessage_Conversation FOREIGN KEY (ConversationId) REFERENCES dbo.Conversation(ConversationId) ON DELETE CASCADE
);
GO

CREATE TABLE dbo.MessageSource
(
    MessageSourceId  BIGINT IDENTITY(1,1) NOT NULL,
    MessageId        BIGINT NOT NULL,
    ChunkId          BIGINT NOT NULL,
    DocumentId       BIGINT NOT NULL,
    PageNumber       INT NULL,
    SourceRank       INT NULL,
    Score             DECIMAL(18,8) NULL,
    CitationText     NVARCHAR(1000) NULL,

    CONSTRAINT PK_MessageSource PRIMARY KEY (MessageSourceId),
    CONSTRAINT CK_MessageSource_PageNumber CHECK (PageNumber IS NULL OR PageNumber >= 0),
    CONSTRAINT CK_MessageSource_SourceRank CHECK (SourceRank IS NULL OR SourceRank > 0),
    CONSTRAINT FK_MessageSource_Message FOREIGN KEY (MessageId) REFERENCES dbo.ConversationMessage(MessageId) ON DELETE CASCADE,
    CONSTRAINT FK_MessageSource_Chunk FOREIGN KEY (ChunkId) REFERENCES dbo.DocumentChunk(ChunkId),
    CONSTRAINT FK_MessageSource_Document FOREIGN KEY (DocumentId) REFERENCES dbo.Document(DocumentId)
);
GO

/* =========================================================
   7. INDEXES
   ========================================================= */

/* School / tenant filtering */
CREATE INDEX IX_User_SchoolId
    ON dbo.[User](SchoolId);

CREATE INDEX IX_Document_SchoolId_Status
    ON dbo.Document(SchoolId, Status);

CREATE INDEX IX_Document_OwnerUserId
    ON dbo.Document(OwnerUserId);

CREATE INDEX IX_Category_SchoolId_Parent
    ON dbo.Category(SchoolId, ParentCategoryId);

CREATE INDEX IX_Tag_SchoolId
    ON dbo.Tag(SchoolId);

/* Library */
CREATE INDEX IX_Document_Title
    ON dbo.Document(Title);

CREATE INDEX IX_DocumentType_TypeCode
    ON dbo.DocumentType(TypeCode);

CREATE INDEX IX_DocumentAuthor_AuthorId
    ON dbo.DocumentAuthor(AuthorId, DocumentId);

CREATE INDEX IX_DocumentTag_TagId
    ON dbo.DocumentTag(TagId, DocumentId);

CREATE INDEX IX_DocumentFile_DocumentId
    ON dbo.DocumentFile(DocumentId, IsActive);

CREATE INDEX IX_DocumentVersion_DocumentId_Current
    ON dbo.DocumentVersion(DocumentId, IsCurrent);

CREATE INDEX IX_DocumentAccess_DocumentId
    ON dbo.DocumentAccess(DocumentId, IsActive);

CREATE INDEX IX_DocumentAccess_SchoolId
    ON dbo.DocumentAccess(SchoolId, IsActive);

CREATE INDEX IX_DocumentAccess_UserId
    ON dbo.DocumentAccess(UserId, IsActive);

CREATE INDEX IX_AccessRequest_Document_Status
    ON dbo.AccessRequest(DocumentId, Status);

CREATE INDEX IX_AccessRequest_RequesterSchool_Status
    ON dbo.AccessRequest(RequesterSchoolId, Status);

/* User activity */
CREATE INDEX IX_Favorite_DocumentId
    ON dbo.Favorite(DocumentId);

CREATE INDEX IX_ReadingHistory_User_LastRead
    ON dbo.ReadingHistory(UserId, LastReadAt DESC);

CREATE INDEX IX_DownloadHistory_User_Date
    ON dbo.DownloadHistory(UserId, DownloadedAt DESC);

CREATE INDEX IX_DownloadHistory_Document_Date
    ON dbo.DownloadHistory(DocumentId, DownloadedAt DESC);

CREATE INDEX IX_Collection_UserId
    ON dbo.Collection(UserId);

CREATE INDEX IX_CollectionDocument_DocumentId
    ON dbo.CollectionDocument(DocumentId, CollectionId);

/* AI */
CREATE INDEX IX_DocumentProcessing_Document_Status
    ON dbo.DocumentProcessing(DocumentId, Status);

CREATE INDEX IX_DocumentChunk_Document_Index
    ON dbo.DocumentChunk(DocumentId, ChunkIndex);

CREATE INDEX IX_DocumentChunk_Version
    ON dbo.DocumentChunk(DocumentVersionId, ChunkIndex);

CREATE INDEX IX_Embedding_ChunkId
    ON dbo.Embedding(ChunkId);

/* RAG */
CREATE INDEX IX_Conversation_User_Updated
    ON dbo.Conversation(UserId, UpdatedAt DESC);

CREATE INDEX IX_ConversationMessage_Conversation_Created
    ON dbo.ConversationMessage(ConversationId, CreatedAt);

CREATE INDEX IX_MessageSource_Message_Rank
    ON dbo.MessageSource(MessageId, SourceRank);

/* =========================================================
   8. SEED DATA
   ========================================================= */

INSERT INTO dbo.Role (RoleCode, RoleName, Description)
VALUES
('SUPER_ADMIN', N'Quản trị hệ thống', N'Quản trị toàn bộ nền tảng EduLib AI'),
('SCHOOL_ADMIN', N'Quản trị trường', N'Quản trị người dùng và tài liệu trong trường'),
('TEACHER', N'Giảng viên', N'Sử dụng và quản lý học liệu theo quyền được cấp'),
('LIBRARIAN', N'Thủ thư', N'Quản lý học liệu thư viện'),
('STUDENT', N'Sinh viên', N'Tra cứu và sử dụng học liệu theo quyền');
GO

INSERT INTO dbo.Permission (PermissionCode, PermissionName, Description)
VALUES
('SCHOOL_VIEW', N'Xem trường', N'Xem thông tin trường'),
('SCHOOL_CREATE', N'Tạo trường', N'Tạo trường mới'),
('SCHOOL_UPDATE', N'Cập nhật trường', N'Cập nhật thông tin trường'),
('USER_VIEW', N'Xem người dùng', N'Xem người dùng'),
('USER_CREATE', N'Tạo người dùng', N'Tạo người dùng'),
('USER_UPDATE', N'Cập nhật người dùng', N'Cập nhật người dùng'),
('USER_LOCK', N'Khóa người dùng', N'Khóa/kích hoạt người dùng'),
('DOCUMENT_VIEW', N'Xem tài liệu', N'Xem tài liệu'),
('DOCUMENT_CREATE', N'Tạo tài liệu', N'Tạo tài liệu'),
('DOCUMENT_UPDATE', N'Cập nhật tài liệu', N'Cập nhật tài liệu'),
('DOCUMENT_DELETE', N'Xóa tài liệu', N'Xóa tài liệu'),
('DOCUMENT_DOWNLOAD', N'Tải tài liệu', N'Tải tài liệu'),
('LICENSE_MANAGE', N'Quản lý license', N'Quản lý quyền sử dụng tài liệu'),
('ACCESS_REQUEST', N'Yêu cầu cấp quyền', N'Gửi/xử lý yêu cầu truy cập'),
('SEARCH', N'Tìm kiếm', N'Tìm kiếm học liệu'),
('RAG_CHAT', N'RAG Chat', N'Trò chuyện với AI dựa trên học liệu'),
('COLLECTION_MANAGE', N'Quản lý bộ sưu tập', N'Tạo và quản lý bộ sưu tập'),
('STATISTICS_VIEW', N'Xem thống kê', N'Xem thống kê hệ thống'),
('PROCESS_DOCUMENT', N'Xử lý tài liệu', N'Chạy pipeline xử lý tài liệu');
GO

INSERT INTO dbo.DocumentType (TypeCode, TypeName, Description)
VALUES
('BOOK', N'Sách', N'Sách điện tử'),
('TEXTBOOK', N'Giáo trình', N'Giáo trình học tập'),
('LECTURE_NOTE', N'Tài liệu bài giảng', N'Tài liệu do giảng viên cung cấp'),
('THESIS', N'Luận văn', N'Luận văn/đồ án'),
('RESEARCH_PAPER', N'Bài nghiên cứu', N'Bài báo hoặc công trình nghiên cứu'),
('REFERENCE', N'Tài liệu tham khảo', N'Tài liệu tham khảo khác');
GO

INSERT INTO dbo.License
(
    LicenseCode, LicenseName, LicenseType, Description,
    CanView, CanDownload, CanShare, CanUseForRAG
)
VALUES
('PUBLIC', N'Công khai', 'PUBLIC', N'Tài liệu có thể được xem công khai', 1, 1, 1, 1),
('SCHOOL_ONLY', N'Nội bộ trường', 'SCHOOL_ONLY', N'Chỉ thành viên trường được cấp quyền', 1, 0, 0, 1),
('LICENSED', N'Được cấp phép', 'LICENSED', N'Tài liệu sử dụng theo quyền được cấp', 1, 0, 0, 1);
GO

/* =========================================================
   9. ID CODE AUTO-GENERATION
   =========================================================
   Các trigger dưới đây tạo mã hiển thị sau khi INSERT.
   PK/FK vẫn dùng BIGINT IDENTITY để tối ưu JOIN/index.
*/

CREATE TRIGGER dbo.TR_School_SetCode
ON dbo.School
AFTER INSERT
AS
BEGIN
    SET NOCOUNT ON;
    UPDATE s
    SET SchoolCode = 'SC' + RIGHT('000000' + CONVERT(VARCHAR(6), s.SchoolId), 6)
    FROM dbo.School s
    INNER JOIN inserted i ON i.SchoolId = s.SchoolId
    WHERE s.SchoolCode IS NULL OR s.SchoolCode = '';
END
GO

CREATE TRIGGER dbo.TR_User_SetCode
ON dbo.[User]
AFTER INSERT
AS
BEGIN
    SET NOCOUNT ON;
    UPDATE u
    SET UserCode = 'US' + RIGHT('000000' + CONVERT(VARCHAR(6), u.UserId), 6)
    FROM dbo.[User] u
    INNER JOIN inserted i ON i.UserId = u.UserId
    WHERE u.UserCode IS NULL OR u.UserCode = '';
END
GO

CREATE TRIGGER dbo.TR_Document_SetCode
ON dbo.Document
AFTER INSERT
AS
BEGIN
    SET NOCOUNT ON;
    UPDATE d
    SET DocumentCode = 'DO' + RIGHT('000000' + CONVERT(VARCHAR(6), d.DocumentId), 6)
    FROM dbo.Document d
    INNER JOIN inserted i ON i.DocumentId = d.DocumentId
    WHERE d.DocumentCode IS NULL OR d.DocumentCode = '';
END
GO

CREATE TRIGGER dbo.TR_Author_SetCode
ON dbo.Author
AFTER INSERT
AS
BEGIN
    SET NOCOUNT ON;
    UPDATE a
    SET AuthorCode = 'AU' + RIGHT('000000' + CONVERT(VARCHAR(6), a.AuthorId), 6)
    FROM dbo.Author a
    INNER JOIN inserted i ON i.AuthorId = a.AuthorId
    WHERE a.AuthorCode IS NULL OR a.AuthorCode = '';
END
GO

CREATE TRIGGER dbo.TR_Category_SetCode
ON dbo.Category
AFTER INSERT
AS
BEGIN
    SET NOCOUNT ON;
    UPDATE c
    SET CategoryCode = 'CA' + RIGHT('000000' + CONVERT(VARCHAR(6), c.CategoryId), 6)
    FROM dbo.Category c
    INNER JOIN inserted i ON i.CategoryId = c.CategoryId
    WHERE c.CategoryCode IS NULL OR c.CategoryCode = '';
END
GO

CREATE TRIGGER dbo.TR_Tag_SetCode
ON dbo.Tag
AFTER INSERT
AS
BEGIN
    SET NOCOUNT ON;
    UPDATE t
    SET TagCode = 'TG' + RIGHT('000000' + CONVERT(VARCHAR(6), t.TagId), 6)
    FROM dbo.Tag t
    INNER JOIN inserted i ON i.TagId = t.TagId
    WHERE t.TagCode IS NULL OR t.TagCode = '';
END
GO

CREATE TRIGGER dbo.TR_Collection_SetCode
ON dbo.Collection
AFTER INSERT
AS
BEGIN
    SET NOCOUNT ON;
    UPDATE c
    SET CollectionCode = 'CL' + RIGHT('000000' + CONVERT(VARCHAR(6), c.CollectionId), 6)
    FROM dbo.Collection c
    INNER JOIN inserted i ON i.CollectionId = c.CollectionId
    WHERE c.CollectionCode IS NULL OR c.CollectionCode = '';
END
GO

/* =========================================================
   10. BASIC SEED TEST
   ========================================================= */

-- Tạo 1 trường demo
INSERT INTO dbo.School
(
    SchoolCode, SchoolName, Address, Email, Phone
)
VALUES
(NULL, N'Trường Đại học Demo', N'Hải Phòng', 'demo@edulib.local', '0123456789');
GO

DECLARE @SchoolId BIGINT = SCOPE_IDENTITY();

-- Tạo Super Admin demo
INSERT INTO dbo.[User]
(
    UserCode, SchoolId, Username, Email, PasswordHash, FullName
)
VALUES
(NULL, NULL, 'superadmin', 'admin@edulib.local', 'CHANGE_ME_HASH', N'Quản trị hệ thống');
GO

DECLARE @AdminId BIGINT = SCOPE_IDENTITY();

DECLARE @SuperAdminRoleId BIGINT =
(
    SELECT RoleId FROM dbo.Role WHERE RoleCode = 'SUPER_ADMIN'
);

INSERT INTO dbo.UserRole (UserId, RoleId)
VALUES (@AdminId, @SuperAdminRoleId);
GO

/* =========================================================
   11. QUICK CHECK
   ========================================================= */

SELECT TABLE_SCHEMA, TABLE_NAME
FROM INFORMATION_SCHEMA.TABLES
WHERE TABLE_TYPE = 'BASE TABLE'
ORDER BY TABLE_NAME;
GO

SELECT SchoolId, SchoolCode, SchoolName
FROM dbo.School;
GO

SELECT UserId, UserCode, Username, FullName
FROM dbo.[User];
GO
USE EduLibAI;

UPDATE [User]
SET PasswordHash = '$2b$10$fv2eKMb5l5Hd1zcO0241zer01LcKI4M8bGHBxLGh1cGLSjsNjvYkK',
    UpdatedAt = SYSDATETIME()
WHERE Username = 'superadmin';