# Custom Input Component Library

A reusable React component library with TextField, Select, and Checkbox components built with TypeScript and React 19 ref forwarding support.

## Features

- **Full TypeScript support** with comprehensive prop types
- **Ref forwarding** for programmatic focus management
- **Form integration** with standard HTML form elements
- **Error handling** with validation states
- **Accessibility** with proper ARIA attributes
- **Styling** with Tailwind CSS classes
- **Helper text** support for guidance and errors

## Components

### TextField

A customizable text input component with label, error, and helper text support.

**Props:**
- Extends all standard HTML input attributes
- `label?: string` - Optional label text
- `error?: string` - Error message to display
- `helperText?: string` - Helper text below input
- `fullWidth?: boolean` - Makes input full width

**Example:**
```tsx
const inputRef = useRef<HTMLInputElement>(null);

<TextField
  ref={inputRef}
  label="Email"
  type="email"
  placeholder="you@example.com"
  fullWidth
  helperText="We'll never share your email"
/>
```

### Select

A dropdown select component with options array support.

**Props:**
- Extends all standard HTML select attributes
- `label?: string` - Optional label text
- `error?: string` - Error message to display
- `helperText?: string` - Helper text below select
- `fullWidth?: boolean` - Makes select full width
- `options: SelectOption[]` - Array of options (required)
- `placeholder?: string` - Placeholder option text

**Example:**
```tsx
const selectRef = useRef<HTMLSelectElement>(null);

const options = [
  { value: 'developer', label: 'Developer' },
  { value: 'designer', label: 'Designer' }
];

<Select
  ref={selectRef}
  label="Role"
  options={options}
  placeholder="Select your role"
  fullWidth
/>
```

### Checkbox

A checkbox component with label and error support.

**Props:**
- Extends all standard HTML input attributes (except type)
- `label?: string` - Label text next to checkbox
- `error?: string` - Error message to display
- `helperText?: string` - Helper text below checkbox

**Example:**
```tsx
const checkboxRef = useRef<HTMLInputElement>(null);

<Checkbox
  ref={checkboxRef}
  label="I agree to the terms"
  required
/>
```

## Usage

### Installation

Import components from the library:

```tsx
import { TextField, Select, Checkbox } from './index';
import type { SelectOption } from './types';
```

### Form Integration

All components work seamlessly with HTML forms:

```tsx
function MyForm() {
  const nameRef = useRef<HTMLInputElement>(null);

  const handleSubmit = (e: FormEvent) => {
    e.preventDefault();

    if (!nameRef.current?.value) {
      nameRef.current?.focus();
      return;
    }

    // Submit form
  };

  return (
    <form onSubmit={handleSubmit}>
      <TextField
        ref={nameRef}
        name="name"
        label="Name"
        required
      />
      <button type="submit">Submit</button>
    </form>
  );
}
```

### Programmatic Focus

Use refs to control focus programmatically:

```tsx
const inputRef = useRef<HTMLInputElement>(null);

const focusInput = () => {
  inputRef.current?.focus();
};

<TextField ref={inputRef} label="Focus me" />
<button onClick={focusInput}>Focus Input</button>
```

### Validation States

Display errors and validation messages:

```tsx
<TextField
  label="Username"
  error="Username is already taken"
  value={username}
/>

<Select
  label="Country"
  options={countries}
  error="Please select a country"
/>

<Checkbox
  label="I agree"
  error="You must agree to continue"
/>
```

## Examples

See `example.tsx` for complete working examples:
- **FormExample**: Full registration form with validation
- **ValidationExample**: Error state demonstrations
- **DisabledExample**: Disabled state handling

## TypeScript Types

All components are fully typed with exported interfaces:

```tsx
interface TextFieldProps extends React.InputHTMLAttributes<HTMLInputElement>
interface SelectProps extends React.SelectHTMLAttributes<HTMLSelectElement>
interface CheckboxProps extends Omit<React.InputHTMLAttributes<HTMLInputElement>, 'type'>
interface SelectOption { value: string; label: string; }
```

## Accessibility

All components include:
- Proper label associations with `htmlFor`
- ARIA attributes (`aria-invalid`, `aria-describedby`)
- Keyboard navigation support
- Focus management
- Screen reader friendly error messages

## Styling

Components use Tailwind CSS utility classes with:
- Consistent spacing and sizing
- Hover and focus states
- Error state styling (red borders/text)
- Disabled state styling
- Responsive design support
