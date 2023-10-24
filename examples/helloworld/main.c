#define IN
#define EFIAPI
#define EFI_SUCCESS 0

typedef unsigned short CHAR16;
typedef unsigned long long EFI_STATUS;
typedef void *EFI_HANDLE;

// The "simple text output protocol" can be used to output to the console:
struct _EFI_SIMPLE_TEXT_OUTPUT_PROTOCOL;
typedef
EFI_STATUS
(EFIAPI *EFI_TEXT_STRING) (
    IN struct _EFI_SIMPLE_TEXT_OUTPUT_PROTOCOL  *This,
    IN CHAR16                                   *String
    );

typedef struct _EFI_SIMPLE_TEXT_OUTPUT_PROTOCOL {
    void             *a;
    EFI_TEXT_STRING  OutputString;
} EFI_SIMPLE_TEXT_OUTPUT_PROTOCOL;

// The "system table" is passed to the application and can be used to access UEFI services and
// various variables, including "ConOut", the console output handle
typedef struct {
    char                             a[52]; // (padding! this structure definition is incomplete!)
    EFI_HANDLE                       ConsoleOutHandle;
    EFI_SIMPLE_TEXT_OUTPUT_PROTOCOL  *ConOut;
} EFI_SYSTEM_TABLE;

// The application entry point:
EFI_STATUS
EFIAPI
EfiMain (
    IN EFI_HANDLE        ImageHandle,
    IN EFI_SYSTEM_TABLE  *SystemTable
    )
{
    SystemTable->ConOut->OutputString(SystemTable->ConOut, L"Hello World!\n");
    return EFI_SUCCESS;
}
