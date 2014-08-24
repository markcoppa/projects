//////////////////////////////////////////////////////////////////////////////
//
//  Module:     peheader.exe - Prints information about PE/COFF and archive files
//  File:       peheader.cpp
//  Author:     Mark Coppa
//
//  Reference:  PE and COFF specification:
//                  http://msdn.microsoft.com/en-us/library/gg463119.aspx
//
//////////////////////////////////////////////////////////////////////////////

#include "peheader.h"

BOOL isPE32Plus = FALSE;
BOOL isPE = FALSE;
BOOL isCOFF = FALSE;
BOOL isManaged = FALSE;
BOOL isArchive = FALSE;

int
__cdecl
wmain(
    int argc,
    __in_ecount(argc) WCHAR *argv[]
     )
{
    if (argc == 1 || argv[1][1] == '?')
    {
        printf("Usage: peheader.exe <file> [-q]\n    [-q] print summary only\n");
        exit(0);
    }

    BOOL quiet = FALSE;

    CoffFileHeader cfh;
    OptionalStdHeader osh;
    OptionalWinHeader owh;
    OptionalDataDirs odd;

    if (argc > 2 && argv[2][1] == 'q')
    {
        quiet = TRUE;
    }

    WCHAR *filename = argv[1];
    if (!quiet)
    {
        PRINT_LOGO(filename);
    }

    FILE *pPE;
    pPE = _wfopen(filename, L"rb");
    if (pPE == NULL)
    {
        printf("Error: Could not open \"%s\" for reading\n", filename);
        exit(1);
    }

    /* Check if file is an archive (uses ar format) */
    char magicAr[7];
    fread(magicAr, 1, 7, pPE);
    if (strncmp(magicAr, "!<arch>", 7) == 0)
    {
        isArchive = TRUE;
        goto finish;
    }

    /* Determine section offsets */
    fseek(pPE, PE_OFFSET_LOCATION, SEEK_SET);
    int offsetSig  = SumBytes(pPE, 2);
    int offsetCoff = offsetSig + 4;
    int offsetStd  = offsetSig + 4 + 20;
    int offsetWin  = offsetSig + 4 + 20 + 28;
    int offsetData = offsetSig + 4 + 20 + 96;

    /* Check that signature exists */
    fseek(pPE, offsetSig, SEEK_SET);
    char buf[4];
    fread(buf, 1, 2, pPE);
    if (buf[0] != 'P' || buf[1] != 'E')
    {
        goto finish;
    }
    else
    {
        isPE = TRUE;
    }

    /* Get COFF file header fields */
    fseek(pPE, offsetCoff, SEEK_SET);
    cfh.Machine = SumBytes(pPE, 2);
    cfh.NumberOfSections = SumBytes(pPE, 2);
    cfh.TimeDateStamp = SumBytes(pPE, 4);
    cfh.PointerToSymbolTable = SumBytes(pPE, 4);
    cfh.NumberOfSymbols = SumBytes(pPE, 4);
    cfh.SizeOfOptionalHeader = SumBytes(pPE, 2);
    cfh.Characteristics = SumBytes(pPE, 2);

    if (cfh.SizeOfOptionalHeader == 0)
    {
        isCOFF = TRUE;
        goto finish;
    }

    /* Get optional header standard fields */
    fseek(pPE, offsetStd, SEEK_SET);
    osh.Magic = SumBytes(pPE, 2);
    osh.MajorLinkerVersion = SumBytes(pPE,1);
    osh.MinorLinkerVersion = SumBytes(pPE, 1);
    osh.SizeOfCode = SumBytes(pPE, 4);
    osh.SizeOfInitializedData = SumBytes(pPE, 4);
    osh.SizeOfUninitializedData = SumBytes(pPE, 4);
    osh.AddressOfEntryPoint = SumBytes(pPE, 4);
    osh.BaseOfCode = SumBytes(pPE, 4);
    if (osh.Magic == 0x10b)
    {
        osh.BaseOfData = SumBytes(pPE, 4);
    }

    /* update offsets for PE32+ file */
    if (osh.Magic == 0x20b)
    {
        isPE32Plus = TRUE;
        offsetWin -= 4;
        offsetData += 16;
    }

    /* Get optional windows header fields */
    fseek(pPE, offsetWin, SEEK_SET);

    /* BUG ImageBase is 8 bytes for PE32+, this is a truncation */
    owh.ImageBase = SumBytes(pPE, 4);
    if (isPE32Plus)
    {
        SumBytes(pPE, 4);   
    }

    owh.SectionAlignment = SumBytes(pPE, 4);
    owh.FileAlignment = SumBytes(pPE, 4);
    owh.MajorOperatingSystemVersion = SumBytes(pPE, 2);
    owh.MinorOperatingSystemVersion = SumBytes(pPE, 2);
    owh.MajorImageVersion = SumBytes(pPE, 2);
    owh.MinorImageVersion = SumBytes(pPE, 2);
    owh.MajorSubsystemVersion = SumBytes(pPE, 2);
    owh.MinorSubsystemVersion = SumBytes(pPE, 2);
    owh.Win32VersionValue = SumBytes(pPE, 4);
    owh.SizeOfImage = SumBytes(pPE, 4);
    owh.SizeOfHeaders = SumBytes(pPE, 4);
    owh.CheckSum = SumBytes(pPE, 4);
    owh.Subsystem = SumBytes(pPE, 2);
    owh.DllCharacteristics = SumBytes(pPE, 2);

    /* BUG these Size items are 8 bytes for PE32+, these are truncations */
    owh.SizeOfStackReserve = SumBytes(pPE, 4);
    if (isPE32Plus)
    {
        SumBytes(pPE, 4);   
    }
    owh.SizeOfStackCommit = SumBytes(pPE, 4);
    if (isPE32Plus)
    {
        SumBytes(pPE, 4);   
    }
    owh.SizeOfHeapReserve = SumBytes(pPE, 4);
    if (isPE32Plus)
    {
        SumBytes(pPE, 4);   
    }
    owh.SizeOfHeapCommit = SumBytes(pPE, 4);
    if (isPE32Plus)
    {
        SumBytes(pPE, 4);   
    }

    owh.LoaderFlags = SumBytes(pPE, 4);
    owh.NumberOfRvaAndSizes = SumBytes(pPE, 4);

    /* Get optional data directories */
    fseek(pPE, offsetData, SEEK_SET);
    odd.ExportTable.VirtualAddress = SumBytes(pPE, 4);
    odd.ExportTable.Size = SumBytes(pPE, 4);
    odd.ImportTable.VirtualAddress = SumBytes(pPE, 4);
    odd.ImportTable.Size = SumBytes(pPE, 4);
    odd.ResourceTable.VirtualAddress = SumBytes(pPE, 4);
    odd.ResourceTable.Size = SumBytes(pPE, 4);
    odd.ExceptionTable.VirtualAddress = SumBytes(pPE, 4);
    odd.ExceptionTable.Size = SumBytes(pPE, 4);
    odd.CertificateTable.VirtualAddress = SumBytes(pPE, 4);
    odd.CertificateTable.Size = SumBytes(pPE, 4);
    odd.BaseRelocationTable.VirtualAddress = SumBytes(pPE, 4);
    odd.BaseRelocationTable.Size = SumBytes(pPE, 4);
    odd.Debug.VirtualAddress = SumBytes(pPE, 4);
    odd.Debug.Size = SumBytes(pPE, 4);
    odd.Architecture.VirtualAddress = SumBytes(pPE, 4);
    odd.Architecture.Size = SumBytes(pPE, 4);
    odd.GlobalPtr.VirtualAddress = SumBytes(pPE, 4);
    odd.GlobalPtr.Size = SumBytes(pPE, 4);
    odd.TLSTable.VirtualAddress = SumBytes(pPE, 4);
    odd.TLSTable.Size = SumBytes(pPE, 4);
    odd.LoadConfigTable.VirtualAddress = SumBytes(pPE, 4);
    odd.LoadConfigTable.Size = SumBytes(pPE, 4);
    odd.BoundImport.VirtualAddress = SumBytes(pPE, 4);
    odd.BoundImport.Size = SumBytes(pPE, 4);
    odd.IAT.VirtualAddress = SumBytes(pPE, 4);
    odd.IAT.Size = SumBytes(pPE, 4);
    odd.DelayImportDescriptor.VirtualAddress = SumBytes(pPE, 4);
    odd.DelayImportDescriptor.Size = SumBytes(pPE, 4);
    odd.CLRRuntimeHeader.VirtualAddress = SumBytes(pPE, 4);
    odd.CLRRuntimeHeader.Size = SumBytes(pPE, 4);
    odd.Reserved.VirtualAddress = SumBytes(pPE, 4);
    odd.Reserved.Size = SumBytes(pPE, 4);

    if (odd.CLRRuntimeHeader.Size > 0)
    {
        isManaged = TRUE;
    }

finish:

    if (!quiet)
    {
        PrintAll(&cfh,
                 &osh,
                 &owh,
                 &odd
                );
    }
    PrintSummary();
    fclose(pPE);

    return 0;
}

/* SumBytes      Convert continguous little endian bytes into their value
 *               assumes input bytes are little endian and positive (unsigned)
 * Parameters    File to read, number of bytes to sum (up to 8)
 * Returns       Sum of bytes, else 0 if count is too big
 */
UINT SumBytes(FILE *pFile, int count)
{
    if (count > 8)
    {
        return 0;
    }

    UINT sum = 0;
    UINT multiplier = 1;
    UCHAR buf[1];

    for (int i = 0; i < count; ++i)
    {
        fread(buf, 1, 1, pFile);
        sum += buf[0] * multiplier;
        multiplier = multiplier<<8;
    }

    return sum;
}


/* PrintMachineType    Print the machine type (that image can run on)
 * Parameters          The type number
 */
void PrintMachineType(int type)
{
    printf("machine (");

    switch(type)
    {
    case 0x0:
        printf("UNKNOWN");
        break;
    case 0x1d3:
        printf("AM33");
        break;
    case 0x8664:
        printf("AMD64");
        break;
    case 0x1c0:
        printf("ARM");
        break;
    case 0x1c4:
        printf("ARMNT");
        break;
    case 0xaa64:
        printf("ARM64");
        break;
    case 0xebc:  // heh
        printf("EBC");
        break;
    case 0x14c:
        printf("I386");
        break;
    case 0x200:
        printf("IA64");
        break;
    case 0x9041:
        printf("M32R");
        break;
    case 0x266:
        printf("MIPS16");
        break;
    case 0x366:
        printf("MIPSFPU");
        break;
    case 0x466:
        printf("MIPSFPU16");
        break;
    case 0x1f0:
        printf("POWERPC");
        break;
    case 0x1f1:
        printf("POWERPCFP");
        break;
    case 0x166:
        printf("R4000");
        break;
    case 0x1a2:
        printf("SH3");
        break;
    case 0x1a3:
        printf("SH3DSP");
        break;
    case 0x1a6:
        printf("SH4");
        break;
    case 0x1a8:
        printf("SH5");
        break;
    case 0x1c2:
        printf("THUMB");
        break;
    case 0x169:
        printf("WCEMIPSV2");
        break;
    default:
        printf("No matching entry");
        break;
    }

    printf(")\n");
}


/* PrintCharacteristics    Print the characteristics given by bit field
 * Parameters              The bit field of characteristics
 */
void PrintCharacteristics(int characteristics)
{
    if (characteristics & 0x0001)
    {
        PRINT_CHAR("Relocations stripped");
    }

    if (characteristics & 0x0002)
    {
        PRINT_CHAR("Executable");
    }

    if (characteristics & 0x0004)
    {
        PRINT_CHAR("Line numbers stripped");
    }

    if (characteristics & 0x0008)
    {
        PRINT_CHAR("Symbols stripped");
    }

    if (characteristics & 0x0010)
    {
        PRINT_CHAR("AGGRESSIVE_WS_TRIM");
    }

    if (characteristics & 0x0020)
    {
        PRINT_CHAR("LARGE_ADDRESS_AWARE");
    }

    if (characteristics & 0x0040)
    {
        PRINT_CHAR("Reserved for future use");
    }

    if (characteristics & 0x0080)
    {
        PRINT_CHAR("BYTES_REVERSED_LO");
    }

    if (characteristics & 0x0100)
    {
        PRINT_CHAR("32 bit word machine");
    }

    if (characteristics & 0x0200)
    {
        PRINT_CHAR("DEBUG_STRIPPED");
    }

    if (characteristics & 0x0400)
    {
        PRINT_CHAR("REMOVABLE_RUN_FROM_SWAP");
    }

    if (characteristics & 0x0800)
    {
        PRINT_CHAR("NET_RUN_FROM_SWAP");
    }

    if (characteristics & 0x1000)
    {
        PRINT_CHAR("SYSTEM");
    }

    if (characteristics & 0x2000)
    {
        PRINT_CHAR("DLL");
    }

    if (characteristics & 0x4000)
    {
        PRINT_CHAR("UP_SYSTEM_ONLY");
    }

    if (characteristics & 0x8000)
    {
        PRINT_CHAR("BYTES_REVERSED_HI");
    }
}


/* PrintOSSubsystem    Print the windows subsystem string
 * Parameters          The subsystem value
 */
void PrintOSSubsystem(int subsystem)
{
    switch (subsystem)
    {
    case 0:
        printf("An unknown subsystem\n");
        break;
    case 1:
        printf("Device drivers and native Windows processs\n");
        break;
    case 2:
        printf("The Windows graphical user interface (GUI) subsystem\n");
        break;
    case 3:
        printf("Windows CUI\n");
        break;
    /* No cases listed for 4-6 */
    case 7:
        printf("The Posix character subsystem\n");
        break;
    /* No case for 8 */
    case 9:
        printf("Windows CE\n");
        break;
    case 10:
        printf("An Extensible Firmware interface (EFI) application\n");
        break;
    case 11:
        printf("An EFI driver with boot services\n");
        break;
    case 12:
        printf("An EFI driver with run-time services\n");
        break;
    case 13:
        printf("An EFI ROM image\n");
        break;
    case 14:
        printf("XBOX\n");
        break;
    default:
        printf("Error: unregistered value\n");
        break;
    }
}


/* PrintDLLCharacteristics    Print the characteristics given by bit field
 * Parameters                 The bit field of characteristics
 */
void PrintDLLCharacteristics(int characteristics)
{
    if (characteristics & 0x0001)
    {
        PRINT_CHAR("Reserved, must be zero (0x01)");
    }

    if (characteristics & 0x0002)
    {
        PRINT_CHAR("Reserved, must be zero (0x02)");
    }

    if (characteristics & 0x0004)
    {
        PRINT_CHAR("Reserved, must be zero (0x04)");
    }

    if (characteristics & 0x0008)
    {
        PRINT_CHAR("Reserved, must be zero (0x08)");
    }

    if (characteristics & 0x0040)
    {
        PRINT_CHAR("Dynamic base");
    }

    if (characteristics & 0x0080)
    {
        PRINT_CHAR("Code integrity checks are enforced");
    }

    if (characteristics & 0x0100)
    {
        PRINT_CHAR("NX compatible");
    }

    if (characteristics & 0x0200)
    {
        PRINT_CHAR("Isolation aware, but do not isolate the image");
    }

    if (characteristics & 0x0400)
    {
        PRINT_CHAR("No structured exception handler");
    }

    if (characteristics & 0x0800)
    {
        PRINT_CHAR("Do not bind the image");
    }

    if (characteristics & 0x1000)
    {
        PRINT_CHAR("Reserved, must be zero (0x1000)");
    }

    if (characteristics & 0x2000)
    {
        PRINT_CHAR("A WDM driver");
    }

    if (characteristics & 0x8000)
    {
        PRINT_CHAR("Terminal Server Aware");
    }
}


/* PrintAll     Print all available sections
 */
void PrintAll(CoffFileHeader *cfh,
              OptionalStdHeader *osh,
              OptionalWinHeader *owh,
              OptionalDataDirs *odd
             )
{
    if (!isPE)
    {
        printf("Error: not a PE file\n");
        return;
    }

    /* For forming version strings */
    char buf[16];

    /* Always print coff header */
    printf("COFF FILE HEADER\n");

    PRINT_HEX(cfh->Machine);
    PrintMachineType(cfh->Machine);

    PRINT_HEX(cfh->NumberOfSections);
    printf("number of sections\n");

    PRINT_HEX(cfh->TimeDateStamp);
    time_t stamp = cfh->TimeDateStamp;
    printf("time date stamp: %s", ctime(&stamp));

    PRINT_HEX(cfh->PointerToSymbolTable);
    printf("file pointer to symbol table\n");

    PRINT_HEX(cfh->NumberOfSymbols);
    printf("number of symbols\n");

    PRINT_HEX(cfh->SizeOfOptionalHeader);
    printf("size of optional header\n");

    PRINT_HEX(cfh->Characteristics);
    printf("characteristics\n");
    PrintCharacteristics(cfh->Characteristics);

    /* Is a COFF file, no other headers to print */
    if (isCOFF)
    {
        printf("COFF file\n");
        return;
    }

    /* Print optional standard header */
    printf("\nOPTIONAL STANDARD HEADER\n");

    PRINT_HEX(osh->Magic);
    printf("magic # %s\n", osh->Magic == 0x10B ? "(PE32)" : "(PE32+)");

    sprintf(buf, "%d.%02d", osh->MajorLinkerVersion, osh->MinorLinkerVersion);
    PRINT_STR(buf);
    printf("linker version\n");

    PRINT_HEX(osh->SizeOfCode);
    printf("size of code\n");

    PRINT_HEX(osh->SizeOfInitializedData);
    printf("size of initialized data\n");

    PRINT_HEX(osh->SizeOfUninitializedData);
    printf("size of uninitialized data\n");

    PRINT_HEX(osh->AddressOfEntryPoint);
    printf("entry point (%08X)\n", owh->ImageBase + osh->AddressOfEntryPoint);

    PRINT_HEX(osh->BaseOfCode);
    printf("base of code\n");

    if (!isPE32Plus)
    {
        PRINT_HEX(osh->BaseOfData);
        printf("base of data\n");
    }

    /* Print optional windows header */
    printf("\nOPTIONAL WINDOWS HEADER\n");
    PRINT_HEX(owh->ImageBase);
    printf("image base\n");    /* TODO print range */

    PRINT_HEX(owh->SectionAlignment);
    printf("section alignment\n");

    PRINT_HEX(owh->FileAlignment);
    printf("file alignment\n");

    sprintf(buf, "%d.%02d", owh->MajorOperatingSystemVersion, owh->MinorOperatingSystemVersion);
    PRINT_STR(buf);
    printf("operating system version\n");

    sprintf(buf, "%d.%02d", owh->MajorImageVersion, owh->MinorImageVersion);
    PRINT_STR(buf);
    printf("image version\n");

    sprintf(buf, "%d.%02d", owh->MajorSubsystemVersion, owh->MinorSubsystemVersion);
    PRINT_STR(buf);
    printf("subsystem version\n");

    PRINT_HEX(owh->Win32VersionValue);
    printf("Win32 version\n");

    PRINT_HEX(owh->SizeOfImage);
    printf("size of image\n");

    PRINT_HEX(owh->SizeOfHeaders);
    printf("size of headers\n");

    PRINT_HEX(owh->CheckSum);
    printf("checksum\n");

    PRINT_HEX(owh->Subsystem);
    PrintOSSubsystem(owh->Subsystem);

    PRINT_HEX(owh->DllCharacteristics);
    printf("DLL characteristics\n");
    PrintDLLCharacteristics(owh->DllCharacteristics);

    PRINT_HEX(owh->SizeOfStackReserve);
    printf("size of stack reserve\n");

    PRINT_HEX(owh->SizeOfStackCommit);
    printf("size of stack commit\n");

    PRINT_HEX(owh->SizeOfHeapReserve);
    printf("size of heap reserve\n");

    PRINT_HEX(owh->SizeOfHeapCommit);
    printf("size of heap commit\n");

    PRINT_HEX(owh->LoaderFlags);
    printf("loader flags\n");

    PRINT_HEX(owh->NumberOfRvaAndSizes);
    printf("number of directories\n");

    /* Print optional data directories */
    printf("\nOPTIONAL DATA DIRECTORIES\n");
    PRINT_DIR(odd->ExportTable.VirtualAddress, odd->ExportTable.Size, "Export Directory");
    PRINT_DIR(odd->ImportTable.VirtualAddress, odd->ImportTable.Size, "Import Directory");
    PRINT_DIR(odd->ResourceTable.VirtualAddress, odd->ResourceTable.Size, "Resource Directory");
    PRINT_DIR(odd->ExceptionTable.VirtualAddress, odd->ExceptionTable.Size, "Exception Directory");
    PRINT_DIR(odd->CertificateTable.VirtualAddress, odd->CertificateTable.Size, "Certificates Directory");
    PRINT_DIR(odd->BaseRelocationTable.VirtualAddress, odd->BaseRelocationTable.Size, "Base Relocation Directory");
    PRINT_DIR(odd->Debug.VirtualAddress, odd->Debug.Size, "Debug Directory");
    PRINT_DIR(odd->Architecture.VirtualAddress, odd->Architecture.Size, "Architecture Directory");
    PRINT_DIR(odd->GlobalPtr.VirtualAddress, odd->GlobalPtr.Size, "Global Pointer Directory");
    PRINT_DIR(odd->TLSTable.VirtualAddress, odd->TLSTable.Size, "Thread Storage Directory");
    PRINT_DIR(odd->LoadConfigTable.VirtualAddress, odd->LoadConfigTable.Size, "Load Configuration Directory");
    PRINT_DIR(odd->BoundImport.VirtualAddress, odd->BoundImport.Size, "Bound Import Directory");
    PRINT_DIR(odd->IAT.VirtualAddress, odd->IAT.Size, "Import Address Table Directory");
    PRINT_DIR(odd->DelayImportDescriptor.VirtualAddress, odd->DelayImportDescriptor.Size, "Delay Import Directory");
    PRINT_DIR(odd->CLRRuntimeHeader.VirtualAddress, odd->CLRRuntimeHeader.Size, "COM Description Directory");
    PRINT_DIR(odd->Reserved.VirtualAddress, odd->Reserved.Size, "Reserved Directory");

    printf("\n");
}


/* PrintSummary    Print basic characteristics of the file
 * Parameters      Uses global characteristics
 */
void PrintSummary()
{
    printf("SUMMARY\n");
    printf("Archive: %s\n", isArchive ? "TRUE" : "FALSE");
    printf("PE: %s\n", isPE ? "TRUE" : "FALSE");
    printf("COFF: %s\n", isCOFF ? "TRUE" : "FALSE");
    printf("Managed: %s\n", isManaged ? "TRUE" : "FALSE");
}
