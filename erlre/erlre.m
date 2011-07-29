#import <Cocoa/Cocoa.h>
#import <CoreServices/CoreServices.h>

DCSDictionaryRef DCSDictionaryCreate(CFURLRef url);
CFArrayRef DCSCopyRecordsForSearchString(DCSDictionaryRef dictionary, CFStringRef string, unsigned long u1, unsigned long u2);
CFDataRef DCSRecordCopyData(CFTypeRef record);
CFStringRef DCSDictionaryGetName(DCSDictionaryRef dictionary);
CFStringRef DCSRecordGetHeadword(CFTypeRef record);
CFArrayRef DCSCopyAvailableDictionaries();
CFStringRef DCSDictionaryGetName(DCSDictionaryRef dictionary);
CFStringRef DCSDictionaryGetShortName(DCSDictionaryRef dictionary);

int main(int argc, char *argv[])
{
  if (argc <= 1) {
    printf("Usage: erlre keyword \n");
    return 1;
  }

  CFArrayRef dicts = DCSCopyAvailableDictionaries();
  DCSDictionaryRef erl_dict = NULL;
  NSString *dict_name;
  for (id d in (NSArray *)dicts) {
    dict_name = (NSString *)DCSDictionaryGetName((DCSDictionaryRef)d);
    // NSLog(@"d %@", dict_name);
    if ([dict_name isEqualToString:@"Erlang OTP Reference"]) {
      erl_dict = (DCSDictionaryRef)d;
    }
  }

  if (erl_dict == NULL) {
    printf("Dictonary not found.");
    return 1;
  }

  NSString *word = [[NSString alloc] initWithUTF8String:argv[1]];
  CFTypeRef dictionary = erl_dict;
  CFArrayRef records_cf = DCSCopyRecordsForSearchString(dictionary, (CFStringRef)word, 1, 0);
  NSArray *records = (NSArray *)records_cf;

  int count = [records count];
  // NSLog(@"count:%d", count);

  if (count == 0) {
    printf("not match.\n");
    return 0;
  }

  NSString *mod = NULL;
  for (id r in records) {
    NSString *w = (NSString *)DCSRecordGetHeadword(r);
    if ([w isEqualToString:word]) {
      mod = w;
    }
  }

  if (count == 1 || mod != NULL) {
    if (mod != NULL) {
      word = mod;
    }
    else {
      word = (NSString *)DCSRecordGetHeadword([records objectAtIndex:0]);
    }
    printf("\n%s\n\n", [word UTF8String]);
    NSString *def_body = (NSString *)DCSCopyTextDefinition(dictionary, (CFStringRef)word, CFRangeMake(0, [word length]));
    for (id line in [def_body componentsSeparatedByString:@"\n"]) {
      printf("    %s\n", [line UTF8String]);
    }
  }
  else {
    for (id record in records) {
      printf("%s\n", [(NSString *)DCSRecordGetHeadword(record) UTF8String]);
    }
  }
  return 0;
}
