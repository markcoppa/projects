#ifndef _PEHEADER
#define _PEHEADER

#include <stdio.h>
#include <stdlib.h>
#include <time.h>
#include <windows.h>

#define PE_OFFSET_LOCATION 60  /* The address of the PE header is given at 60 bytes into the image */
#define PRINT_LOGO(filename) printf("PE/COFF header dump\n\nDump of %S\n\n", filename);
#define PRINT_CHAR(value) printf("             %s\n", value);
#define PRINT_HEX(value) printf("%10X ", value)
#define PRINT_STR(value) printf("%10s ", value)
#define PRINT_DIR(address, size, item) printf("%10X [%8X] RVA [size] of %s\n", address, size, item);

typedef struct
{
    UINT Machine;                // 2 bytes
    UINT NumberOfSections;       // 2 bytes
    UINT TimeDateStamp;          // 4 bytes
    UINT PointerToSymbolTable;   // 4 bytes
    UINT NumberOfSymbols;        // 4 bytes
    UINT SizeOfOptionalHeader;   // 2 bytes
    UINT Characteristics;        // 2 bytes
} CoffFileHeader;

typedef struct
{
    UINT Magic;                     // 2 bytes
    UINT MajorLinkerVersion;        // 1 byte
    UINT MinorLinkerVersion;        // 1 bytes
    UINT SizeOfCode;                // 4 bytes
    UINT SizeOfInitializedData;     // 4 bytes
    UINT SizeOfUninitializedData;   // 4 bytes
    UINT AddressOfEntryPoint;       // 4 bytes
    UINT BaseOfCode;                // 4 bytes
    UINT BaseOfData;                // 4 bytes (PE32 only)
} OptionalStdHeader;

typedef struct
{
    UINT ImageBase;                     // 4 bytes (8 for PE32+)
    UINT SectionAlignment;              // 4 bytes
    UINT FileAlignment;                 // 4 bytes
    UINT MajorOperatingSystemVersion;   // 2 bytes
    UINT MinorOperatingSystemVersion;   // 2 bytes
    UINT MajorImageVersion;             // 2 bytes
    UINT MinorImageVersion;             // 2 bytes
    UINT MajorSubsystemVersion;         // 2 bytes
    UINT MinorSubsystemVersion;         // 2 bytes
    UINT Win32VersionValue;             // 4 bytes
    UINT SizeOfImage;                   // 4 bytes
    UINT SizeOfHeaders;                 // 4 bytes
    UINT CheckSum;                      // 4 bytes
    UINT Subsystem;                     // 2 bytes
    UINT DllCharacteristics;            // 2 bytes
    UINT SizeOfStackReserve;            // 4 bytes (8 for PE32+)
    UINT SizeOfStackCommit;             // 4 bytes (8 for PE32+)
    UINT SizeOfHeapReserve;             // 4 bytes (8 for PE32+)
    UINT SizeOfHeapCommit;              // 4 bytes (8 for PE32+)
    UINT LoaderFlags;                   // 4 bytes
    UINT NumberOfRvaAndSizes;           // 4 bytes
} OptionalWinHeader;

typedef struct
{
    UINT VirtualAddress;    // 4 bytes
    UINT Size;              // 4 bytes
} DataDirectory;

typedef struct
{
    DataDirectory ExportTable;
    DataDirectory ImportTable;
    DataDirectory ResourceTable;
    DataDirectory ExceptionTable;
    DataDirectory CertificateTable;
    DataDirectory BaseRelocationTable;
    DataDirectory Debug;
    DataDirectory Architecture;
    DataDirectory GlobalPtr;
    DataDirectory TLSTable;
    DataDirectory LoadConfigTable;
    DataDirectory BoundImport;
    DataDirectory IAT;
    DataDirectory DelayImportDescriptor;
    DataDirectory CLRRuntimeHeader;
    DataDirectory Reserved;
} OptionalDataDirs;


UINT SumBytes(FILE *pFile, int count);
void PrintMachineType(int type);
void PrintCharacteristics(int characteristics);
void PrintOSSubsystem(int subsystem);
void PrintAll(CoffFileHeader *cfh,
              OptionalStdHeader *osh,
              OptionalWinHeader *owh,
              OptionalDataDirs *odd
             );
void PrintSummary();

#endif _PEHEADER
