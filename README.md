# EDUtest chatcommands

This fork introduces the following changes:
- `student` privilege disabled to make all non-teacher users 'students' by default
- `teacher` privilege changed to `instructor` to avoid conflict with Sfan5's `teaching` mod
- added chat command `heal <subject>` to help classes work in enable_damage=on environments
- added chat command `announce <message>` which displays message in a custom formspec

The goal of the EDUtest project is to facilitate the usage of Minetest
in an educational context.

This mod provides chatcommands for the educational staff.

## setup

The commands expect ~~the students to be marked with the "student" privilege~~,
while the teacher(s) are marked with the "teacher" privilege.

~~A common way to set this up would be to add "student" to the default_privs
server configuration option, and to revoke it manually from the teacher(s),
while granting them the "teacher" privilege.~~
