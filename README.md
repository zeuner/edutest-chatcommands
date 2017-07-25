# EDUtest chatcommands

The goal of the EDUtest project is to facilitate the usage of Minetest
in an educational context.

This mod provides chatcommands for the educational staff.

## setup

The commands expect the students to be marked with the "student" privilege,
while the teacher(s) are marked with the "teacher" privilege.

A common way to set this up would be to add "student" to the default_privs
server configuration option, and to revoke it manually from the teacher(s),
while granting them the "teacher" privilege.
