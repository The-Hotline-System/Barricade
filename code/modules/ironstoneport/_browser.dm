//Defines for the browser datum and its subtypes.

#define NULLABLE(condition) (condition || null)
#define CHOICE_OK "OK"

#define CHOICE_YES "YES"
#define CHOICE_NO "NO"
#define CHOICE_NEVER "NEVER"

#define CHOICE_CONFIRM "CONFIRM"
#define CHOICE_CANCEL "CANCEL"

#define DEFAULT_INPUT_CONFIRMATIONS list(CHOICE_CONFIRM, CHOICE_CANCEL)
#define DEFAULT_INPUT_CHOICES list(CHOICE_YES, CHOICE_NO)

#define isclient(A) istype(A, /client)
