Handy recipes:
1. Migrate selected string(s) from Android source to your Android project resources
 `syncxmlstrings.rb --from /cm/frameworks/base/res/res/ --to /your/android/project/res/ -s key,key2...`
2. Move all non existings strings from one resource dir to another
 `syncxmlstrings.rb --from /project1/res/ --to /project2/res/ --dont-replace`
