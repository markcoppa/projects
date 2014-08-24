#
# peheader
#
# Dump the contents of a PE file header
# Roughly equivalent to link /dump /header
#
# Author:
#         Mark Coppa
#
# Notes:  
#         This script provides a platform-agnostic starting point for dumping
#         PE/COFF file information.
#
#         It can be extended as needed to gather specific data, such as
#         managed code assembly information.
#
#         PE/COFF specification: http://msdn.microsoft.com/en-us/gg463119.aspx
#
# Upgrades:
#         Fix timestamp format
#

import datetime
import os.path
import struct
import sys

# The address of the PE header is given at 60 bytes
PE_OFFSET_LOCATION = 60

FormatString = "{:>10} {}"
FormatHex = "{:10X} {}"
FormatVersion = "{:#7}.{:02} {}"
FormatChar = "             {}"
FormatDir = '{:10X} [{:8X}] RVA [size] of {}'

usage = 'Usage: ' + sys.argv[0] + ' <file>'


# GetMachineString
# Get the string representation for the machine hex value
#
##############################################################################
def GetMachineString(type):
    if type == 0x0:
        return 'UNKNOWN'
    elif type == 0x1d3:
        return 'AM33'
    elif type == 0x8664:
        return 'AMD64'
    elif type == 0x1c0:
        return 'ARM'
    elif type == 0x1c4:
        return 'ARMNT'
    elif type == 0xaa64:
        return 'ARM64'
    elif type == 0xebc:  # heh
        return 'EBC'
    elif type == 0x14c:
        return 'I386'
    elif type == 0x200:
        return 'IA64'
    elif type == 0x9041:
        return 'M32R'
    elif type == 0x266:
        return 'MIPS16'
    elif type == 0x366:
        return 'MIPSFPU'
    elif type == 0x466:
        return 'MIPSFPU16'
    elif type == 0x1f0:
        return 'POWERPC'
    elif type == 0x1f1:
        return 'POWERPCFP'
    elif type == 0x166:
        return 'R4000'
    elif type == 0x1a2:
        return 'SH3'
    elif type == 0x1a3:
        return 'SH3DSP'
    elif type == 0x1a6:
        return 'SH4'
    elif type == 0x1a8:
        return 'SH5'
    elif type == 0x1c2:
        return 'THUMB'
    elif type == 0x169:
        return 'WCEMIPSV2'
    else:
        return 'No matching entry'

#
# PrintCharacteristics
# Get the strings for each characteristic in the bitfield
# Upgrade:  Replace all results with real string to be printed
#
##############################################################################
def PrintCharacteristics(characteristics):
    if characteristics & 0x0001:
        print FormatChar.format('Relocations stripped')
    if characteristics & 0x0002:
        print FormatChar.format('Executable')
    if characteristics & 0x0004:
        print FormatChar.format('Line numbers stripped')
    if characteristics & 0x0008:
        print FormatChar.format('Symbols stripped')
    if characteristics & 0x0010:
        print FormatChar.format('AGGRESSIVE_WS_TRIM')
    if characteristics & 0x0020:
        print FormatChar.format('Application can handle large (>2GB) addresses')
    if characteristics & 0x0040:
        print FormatChar.format('Reserved for future use')
    if characteristics & 0x0080:
        print FormatChar.format('BYTES_REVERSED_LO')
    if characteristics & 0x0100:
        print FormatChar.format('32 bit word machine')
    if characteristics & 0x0200:
        print FormatChar.format('DEBUG_STRIPPED')
    if characteristics & 0x0400:
        print FormatChar.format('REMOVABLE_RUN_FROM_SWAP')
    if characteristics & 0x0800:
        print FormatChar.format('NET_RUN_FROM_SWAP')
    if characteristics & 0x1000:
        print FormatChar.format('SYSTEM')
    if characteristics & 0x2000:
        print FormatChar.format('DLL')
    if characteristics & 0x4000:
        print FormatChar.format('UP_SYSTEM_ONLY')
    if characteristics & 0x8000:
        print FormatChar.format('BYTES_REVERSED_HI')

#
# PrintDLLCharacteristics
# Get the strings for each DLL characteristic in the bitfield
#
##############################################################################
def PrintDLLCharacteristics(characteristics):
    if characteristics & 0x0001:
        print FormatChar.format('Reserved, must be zero (0x01)')
    if characteristics & 0x0002:
        print FormatChar.format('Reserved, must be zero (0x02)')
    if characteristics & 0x0004:
        print FormatChar.format('Reserved, must be zero (0x04)')
    if characteristics & 0x0008:
        print FormatChar.format('Reserved, must be zero (0x08)')
    if characteristics & 0x0040:
        print FormatChar.format('Dynamic base')
    if characteristics & 0x0080:
        print FormatChar.format('Code integrity checks are enforced')
    if characteristics & 0x0100:
        print FormatChar.format('NX compatible')
    if characteristics & 0x0200:
        print FormatChar.format('Isolation aware, but do not isolate the image')
    if characteristics & 0x0400:
        print FormatChar.format('No structured exception handler')
    if characteristics & 0x0800:
        print FormatChar.format('Do not bind the image')
    if characteristics & 0x1000:
        print FormatChar.format('Reserved, must be zero (0x1000)')
    if characteristics & 0x2000:
        print FormatChar.format('Reserved, must be zero (0x1000)')
    if characteristics & 0x8000:
        print FormatChar.format('Terminal Server Aware')

# Main
#
#
##############################################################################


# Open file provided by user
if len(sys.argv) != 2:
    print usage
    exit(1)

input = sys.argv[1]
if not os.path.isfile(input):
    print 'File "' + input + '" not found'
    print usage
    exit(1)

f = open(input, "rb");
print 'PE/COFF header dump\n\nDump of ' + input + '\n'

# Determine section offsets
f.seek(PE_OFFSET_LOCATION)
offsetSig  = struct.unpack('<H', f.read(2))[0]
offsetCoff = offsetSig + 4
offsetStd  = offsetSig + 4 + 20
offsetWin  = offsetSig + 4 + 20 + 28
offsetData = offsetSig + 4 + 20 + 96

# Check that signature exists
f.seek(offsetSig)
buf = f.read(2)
if buf[0] != 'P' or buf[1] != 'E':
    print "Not a PE file"
    f.close
    exit(0)

# Get COFF file header fields
f.seek(offsetCoff)
CoffHeaderFields = ('machine',                        # 2 bytes
                    'number of sections',             # 2 bytes
                    'time date stamp',                # 4 bytes
                    'file pointer to symbol table',   # 4 bytes
                    'number of symbols',              # 4 bytes
                    'size of optional header',        # 2 bytes
                    'characteristics',                # 2 bytes
                   )
CoffHeaderValues = list(struct.unpack('<HHLLLHH', f.read(20)))

# Print file header fields
print "FILE HEADER VALUES"
print FormatHex.format(CoffHeaderValues[0], CoffHeaderFields[0] + ' (' + GetMachineString(CoffHeaderValues[0]) + ')')
print FormatHex.format(CoffHeaderValues[1], CoffHeaderFields[1])
# TODO fix this to be formatted like Mon Jul 21 10:13:11 2014 (currently is 2000-09-07 17:52:05)
print FormatHex.format(CoffHeaderValues[2], CoffHeaderFields[2] + ': ' + str(datetime.datetime.fromtimestamp(CoffHeaderValues[2])))
for i in range(3,7):
    print FormatHex.format(CoffHeaderValues[i], CoffHeaderFields[i])
PrintCharacteristics(CoffHeaderValues[6])
print

# If optional header size is zero, then file is pure COFF
if CoffHeaderValues[5] == 0:
    f.close
    exit(0)

# Get optional header standard fields
f.seek(offsetStd)
StdHeaderFields = ('magic #',                      # 2 bytes
                   'MajorLinkerVersion',           # 1 byte
                   'MinorLinkerVersion',           # 1 byte
                   'size of code',                 # 4 bytes
                   'size of initialized data',     # 4 bytes
                   'size of uninitialized data',   # 4 bytes
                   'entry point',                  # 4 bytes
                   'base of code',                 # 4 bytes
                   'base of data'                  # 4 bytes
                  )
StdHeaderValues = list(struct.unpack('<HBBLLLLL', f.read(24)))

if StdHeaderValues[0] == 0x10b:
    buf = f.read(4)
    StdHeaderValues.append(struct.unpack('<L', f.read(4)))
else:
    StdHeaderValues.append('[none]')

# Update offsets for PE32+ file
IsPE32Plus = False
if StdHeaderValues[0] == 0x20b:
    IsPE32Plus = True
    offsetWin -= 4
    offsetData += 16

# Print optional standard header
print "OPTIONAL HEADER VALUES"
print FormatString.format(StdHeaderValues[0],
                          StdHeaderFields[0] + (' (PE32)' if StdHeaderValues[0] == 0x10B else ' (PE32+)'))
print FormatVersion.format(StdHeaderValues[1], StdHeaderValues[2], 'linker version')

for i in range(3,8):
    print FormatHex.format(StdHeaderValues[i], StdHeaderFields[i])

if not IsPE32Plus:
    print FormatHex.format(StdHeaderValues[i], StdHeaderFields[i])

print

# Get optional windows header fields
f.seek(offsetWin)

OptWinFields = ('image base',                   # 4 bytes (8 for PE32+)
                'section alignment',            # 4 bytes
                'file alignment',               # 4 bytes
                'MajorOperatingSystemVersion',  # 2 bytes
                'MinorOperatingSystemVersion',  # 2 bytes
                'MajorImageVersion',            # 2 bytes
                'MinorImageVersion',            # 2 bytes
                'MajorSubsystemVersion',        # 2 bytes
                'MinorSubsystemVersion',        # 2 bytes
                'Win32 version',                # 4 bytes
                'size of image',                # 4 bytes
                'size of headers',              # 4 bytes
                'checksum',                     # 4 bytes
                'Windows CUI',                  # 2 bytes
                'DLL characteristics',          # 2 bytes
                'size of stack reserve',        # 4 bytes (8 for PE32+)
                'size of stack commit',         # 4 bytes (8 for PE32+)
                'size of heap reserve',         # 4 bytes (8 for PE32+)
                'size of heap commit',          # 4 bytes (8 for PE32+)
                'loader flags',                 # 4 bytes
                'number of directories',        # 4 bytes
               )

OptWinValues = [None] * 21
if IsPE32Plus:
    OptWinValues = list(struct.unpack('<QLLHHHHHHLLLLHHQQQQLL', f.read(88)))
else:
    OptWinValues = list(struct.unpack('<LLLHHHHHHLLLLHHLLLLLL', f.read(68)))

# Print optional windows header
print "OPTIONAL WINDOWS HEADER VALUES"

for i in range(0, 3):
    print FormatHex.format(OptWinValues[i], OptWinFields[i])

print FormatVersion.format(OptWinValues[3], OptWinValues[4], 'os version')
print FormatVersion.format(OptWinValues[5], OptWinValues[6], 'image version')
print FormatVersion.format(OptWinValues[7], OptWinValues[8], 'subsystem version')

for i in range(9, 15):
    print FormatHex.format(OptWinValues[i], OptWinFields[i])
PrintDLLCharacteristics(OptWinValues[14])

for i in range(16, len(OptWinFields)):
    print FormatHex.format(OptWinValues[i], OptWinFields[i])

print

# Get optional data directories
f.seek(offsetData)
(ExportTable_va, ExportTable_size,
 ImportTable_va, ImportTable_size,
 ResourceTable_va, ResourceTable_size,
 ExceptionTable_va, ExceptionTable_size,
 CertificateTable_va, CertificateTable_size,
 BaseRelocationTable_va, BaseRelocationTable_size,
 Debug_va, Debug_size,
 Architecture_va, Architecture_size,
 GlobalPtr_va, GlobalPtr_size,
 TLSTable_va, TLSTable_size,
 LoadConfigTable_va, LoadConfigTable_size,
 BoundImport_va, BoundImport_size,
 IAT_va, IAT_size,
 DelayImportDescriptor_va, DelayImportDescriptor_size,
 CLRRuntimeHeader_va, CLRRuntimeHeader_size,
 Reserved_va, Reserved_size) = struct.unpack('<LLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLL', f.read(128))

IsManaged = True if CLRRuntimeHeader_size > 0 else False

print "OPTIONAL DATA DIRECTORIES"
print FormatDir.format(ExportTable_va, ExportTable_size, 'Export Directory')
print FormatDir.format(ImportTable_va, ImportTable_size, 'Import Directory')
print FormatDir.format(ResourceTable_va, ResourceTable_size, 'Resource Directory')
print FormatDir.format(ExceptionTable_va, ExceptionTable_size, 'Exception Directory')
print FormatDir.format(CertificateTable_va, CertificateTable_size, 'Exception Directory')
print FormatDir.format(BaseRelocationTable_va, BaseRelocationTable_size, 'Base Relocation Directory')
print FormatDir.format(Debug_va, Debug_size, 'Debug Directory')
print FormatDir.format(Architecture_va, Architecture_size, 'Architecture Directory')
print FormatDir.format(GlobalPtr_va, GlobalPtr_size, 'Global Pointer Directory')
print FormatDir.format(TLSTable_va, TLSTable_size, 'Thread Storage Directory')
print FormatDir.format(LoadConfigTable_va, LoadConfigTable_size, 'Load Configuration Directory')
print FormatDir.format(BoundImport_va, BoundImport_size, 'Bound Import Directory')
print FormatDir.format(IAT_va, IAT_size, 'Import Address Table Directory')
print FormatDir.format(DelayImportDescriptor_va, DelayImportDescriptor_size, 'Delay Import Directory')
print FormatDir.format(CLRRuntimeHeader_va, CLRRuntimeHeader_size, 'COM Descriptor Directory')
print FormatDir.format(Reserved_va, Reserved_size, 'Reserved Directory')


f.close

