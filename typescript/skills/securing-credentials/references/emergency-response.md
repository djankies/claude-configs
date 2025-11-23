# Emergency Response for Security Breaches

## If You Find Insecure Password Storage

**IMMEDIATE ACTIONS**:

1. **Stop the application** (if running)
2. **Do NOT commit the code**
3. **Implement proper hashing** (bcrypt/argon2)
4. **Force password reset for all users**
5. **Notify security team**
6. **Assess breach scope**
7. **Notify users if breached**

## Migration Path from Insecure Storage

```typescript
async function migratePasswords() {
  const users = await database.users.find({ passwordMigrated: false });

  for (const user of users) {

    if (user.plaintextPassword) {
      user.passwordHash = await hashPassword(user.plaintextPassword);
      delete user.plaintextPassword;
      user.passwordMigrated = true;
      await database.users.update(user);
    } else {

      user.requirePasswordReset = true;
      user.passwordMigrated = true;
      await database.users.update(user);
    }
  }
}
```

## Legal and Compliance Considerations

- Document the incident
- Follow breach notification laws (GDPR, CCPA, etc.)
- Preserve evidence for investigation
- Consider engaging legal counsel
- Prepare public communications if needed

## Prevention for Future

- Implement code review processes
- Use automated security scanning
- Train developers on security best practices
- Establish security champions in teams
- Regular security audits
