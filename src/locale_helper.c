#include <langinfo.h>
#include <stdlib.h>

/* Returns Monday=0 .. Sunday=6, matching Python calendar module. */
int
nicecalendar_locale_first_weekday (void)
{
#ifdef _NL_TIME_FIRST_WEEKDAY
  const char *s = nl_langinfo (_NL_TIME_FIRST_WEEKDAY);
  if (s != NULL && s[0] != '\0') {
    int v = atoi (s); /* 1=Sunday .. 7=Saturday */
    if (v >= 1 && v <= 7)
      return (v + 5) % 7; /* Sun→6, Mon→0 */
  }
#endif
  return 0; /* Monday */
}
