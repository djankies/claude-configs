# shadcn/ui Research

## Overview

- **Current Version**: v3.5.0 (Latest stable as of October 2025)
- **Official Documentation**: https://ui.shadcn.com
- **GitHub Repository**: https://github.com/shadcn-ui/ui
- **License**: MIT
- **Purpose in Project**: Re-usable component library built with Radix UI and Tailwind CSS
- **Last Updated**: November 19, 2025

## What is shadcn/ui?

shadcn/ui is **not a traditional component library** or npm package. Instead, it's a collection of re-usable components that you can copy and paste (or install via CLI) directly into your application. The philosophy is **"components you own"** - giving you full control over styling and functionality while maintaining consistency.

**Key Philosophy**: Rather than treating components as dependencies, shadcn/ui provides copy-paste component code that becomes part of your codebase. This approach enables:

- Full customization without fighting against library constraints
- No version lock-in or breaking changes from upstream updates
- Direct modification of component code to fit specific needs
- Complete ownership and transparency of UI code

## Core Technologies

- **TypeScript**: 89.3% of codebase
- **React**: Component framework
- **Radix UI**: Accessible, unstyled component primitives
- **Tailwind CSS**: Utility-first styling framework
- **CVA (Class Variance Authority)**: For component variants
- **MDX**: 9.7% for documentation

## Installation

### Prerequisites

- Node.js (recommended: latest LTS)
- Package manager: pnpm, npm, yarn, or bun
- Framework: Next.js, Vite, React Router, Remix, Astro, TanStack Start, Laravel, or custom setup

### Quick Start

#### Initialize a New Project

```bash
pnpm dlx shadcn@latest init
```

This command will:

1. Install dependencies (tailwind-merge, clsx, etc.)
2. Add the `cn()` utility function
3. Configure CSS variables
4. Create `components.json` configuration file
5. Set up basic theming structure

#### Init Command Options

```bash
pnpm dlx shadcn@latest init [options]

Options:
  -t, --template <template>       Select template (next, next-monorepo)
  -b, --base-color <color>       Choose base color (neutral, gray, zinc, stone, slate)
  -y, --yes                      Skip confirmation prompts (default: true)
  -f, --force                    Overwrite existing configuration
  --src-dir / --no-src-dir       Control src directory usage
  --css-variables                Enable CSS variable theming
  --no-css-variables             Use utility classes instead
  --no-base-style                Skip base style installation
  -c, --cwd <directory>          Specify working directory
```

### Adding Components

```bash
pnpm dlx shadcn@latest add button
pnpm dlx shadcn@latest add button card dialog
pnpm dlx shadcn@latest add --all
```

#### Add Command Options

- `-y, --yes`: Skip confirmation prompts
- `-o, --overwrite`: Overwrite existing files
- `-a, --all`: Add all available components
- `-p, --path <path>`: Specify custom installation path
- `-s, --silent`: Suppress output messages

### Framework-Specific Installation

The installation process varies by framework. Supported frameworks include:

- **Next.js**: Full-featured React framework with SSR/SSG
- **Vite**: Fast build tool for modern web projects
- **Laravel**: PHP framework with frontend tooling support
- **React Router**: Client-side routing solution
- **Remix**: Full-stack React framework
- **Astro**: Static site builder with component support
- **TanStack Start**: Full-stack React framework
- **TanStack Router**: Advanced routing library
- **Manual**: For custom setups and other frameworks

## Configuration

### components.json Structure

The `components.json` file holds all configuration for the shadcn CLI. It's **only required if using the CLI**; copy-paste method doesn't need it.

```json
{
  "$schema": "https://ui.shadcn.com/schema.json",
  "style": "new-york",
  "rsc": false,
  "tsx": true,
  "tailwind": {
    "config": "",
    "css": "src/styles/globals.css",
    "baseColor": "neutral",
    "cssVariables": true,
    "prefix": ""
  },
  "aliases": {
    "components": "@/components",
    "utils": "@/lib/utils",
    "ui": "@/components/ui",
    "lib": "@/lib",
    "hooks": "@/hooks"
  },
  "iconLibrary": "lucide"
}
```

### Configuration Options

#### Style

- **Current**: `"new-york"` (the `default` style is deprecated)
- **Cannot be changed after initialization**

#### Tailwind Configuration

**tailwind.config**: Path to your Tailwind config file (leave blank for Tailwind CSS v4)

**tailwind.css**: Path to the CSS file importing Tailwind

**tailwind.baseColor**: Sets the default color palette

- Options: `"gray"`, `"neutral"`, `"slate"`, `"stone"`, `"zinc"`
- **Cannot be changed after initialization**

**tailwind.cssVariables**: Choose between CSS variables (`true`) or utility classes (`false`)

- **Recommended**: `true` for CSS variables
- **Cannot be changed after initialization**

**tailwind.prefix**: Adds a prefix to Tailwind utility classes (e.g., `"tw-"`)

#### Feature Flags

**rsc**: Enables React Server Components support

- Automatically adds `"use client"` directives to client components

**tsx**: Set to `false` to generate JavaScript (`.jsx`) instead of TypeScript (`.tsx`)

#### Import Aliases

Configure path aliases for organized imports:

```typescript
{
  "aliases": {
    "utils": "@/lib/utils",
    "components": "@/components",
    "ui": "@/components/ui",
    "lib": "@/lib",
    "hooks": "@/hooks"
  }
}
```

Don't forget to configure matching aliases in `tsconfig.json`:

```json
{
  "compilerOptions": {
    "baseUrl": ".",
    "paths": {
      "@/*": ["./*"]
    }
  }
}
```

#### Registries

Configure multiple resource registries for installing components from various sources:

**Basic Setup:**

```json
{
  "registries": {
    "@v0": "https://v0.dev/chat/b/{name}",
    "@acme": "https://registry.acme.com/resources/{name}.json"
  }
}
```

**Advanced with Authentication:**

```json
{
  "registries": {
    "@shadcn": "https://ui.shadcn.com/r/{name}.json",
    "@company-ui": {
      "url": "https://registry.company.com/ui/{name}.json",
      "headers": {
        "Authorization": "Bearer ${COMPANY_TOKEN}"
      }
    },
    "@team": {
      "url": "https://team.company.com/{name}.json",
      "params": {
        "team": "frontend",
        "version": "${REGISTRY_VERSION}"
      }
    }
  }
}
```

**Usage:**

```bash
npx shadcn@latest add @v0/dashboard
npx shadcn@latest add @acme/header @lib/auth-utils
```

**Security Best Practice:**

```bash
REGISTRY_TOKEN=your_secret_token_here
```

Store tokens in `.env.local` and reference them with `${VARIABLE_NAME}` syntax.

## CLI Commands Reference

### init

Initialize configuration and dependencies for new projects.

```bash
pnpm dlx shadcn@latest init [options]
```

### add

Add components and dependencies to your project.

```bash
pnpm dlx shadcn@latest add [component]
pnpm dlx shadcn@latest add button card dialog
```

### view

Preview registry items before installation.

```bash
pnpm dlx shadcn@latest view [item]
pnpm dlx shadcn@latest view button card dialog
pnpm dlx shadcn@latest view @acme/auth @v0/dashboard
```

### search / list

Discover items from registries (list is an alias for search).

```bash
pnpm dlx shadcn@latest search [registry]
pnpm dlx shadcn@latest search @shadcn -q "button"
pnpm dlx shadcn@latest search @shadcn @v0 @acme

Options:
  -q, --query <string>    Search with query string
  -l, --limit <number>    Maximum items per registry (default: 100)
  -o, --offset <number>   Skip items (default: 0)
```

### build

Generate registry JSON files from configuration (for creating your own registry).

```bash
pnpm dlx shadcn@latest build [registry]
pnpm dlx shadcn@latest build --output ./public/registry

Options:
  [registry]              Path to registry.json (default: "./registry.json")
  -o, --output <path>     Destination directory (default: "./public/r")
```

## Theming

### CSS Variables vs Utility Classes

shadcn/ui offers two theming approaches:

**CSS Variables (Recommended):**

- Set `tailwind.cssVariables: true` in `components.json`
- Enables semantic color tokens like `bg-background`, `text-foreground`
- More flexible for theme switching
- Easier to maintain consistency

**Utility Classes:**

- Set `cssVariables: false`
- Uses direct Tailwind utilities like `bg-zinc-950`, `dark:bg-white`
- More explicit but less flexible

### Color Convention

The system uses a simple `background` and `foreground` pairing:

- The `background` suffix is omitted when the variable is used for the background color
- Example: `--primary` for background, `--primary-foreground` for text contrast

### Available CSS Variables

Core variables include:

```css
:root {
  --background: oklch(...);
  --foreground: oklch(...);

  --primary: oklch(...);
  --primary-foreground: oklch(...);

  --secondary: oklch(...);
  --secondary-foreground: oklch(...);

  --accent: oklch(...);
  --accent-foreground: oklch(...);

  --muted: oklch(...);
  --muted-foreground: oklch(...);

  --destructive: oklch(...);
  --destructive-foreground: oklch(...);

  --border: oklch(...);
  --input: oklch(...);
  --ring: oklch(...);

  --card: oklch(...);
  --card-foreground: oklch(...);

  --popover: oklch(...);
  --popover-foreground: oklch(...);

  --sidebar: oklch(...);
  --sidebar-foreground: oklch(...);
  --sidebar-border: oklch(...);
  --sidebar-accent: oklch(...);
  --sidebar-accent-foreground: oklch(...);

  --chart-1: oklch(...);
  --chart-2: oklch(...);
  --chart-3: oklch(...);
  --chart-4: oklch(...);
  --chart-5: oklch(...);

  --radius: 0.5rem;
}
```

### Dark Mode Support

Variables automatically adjust within `.dark` pseudo-class selectors:

```css
.dark {
  --background: oklch(...);
  --foreground: oklch(...);
}
```

The oklch color format provides perceptually uniform color transitions between light and dark themes.

### Custom Colors

Add new colors by defining them under `:root` and `.dark`, then expose them via `@theme inline` directive:

```css
:root {
  --warning: oklch(0.84 0.16 84);
  --warning-foreground: oklch(0.28 0.07 46);
}

.dark {
  --warning: oklch(...);
  --warning-foreground: oklch(...);
}
```

### Base Color Options

Predefined palettes optimized for different design aesthetics:

- **Neutral**: Balanced, modern aesthetic
- **Stone**: Warm, earthy tones
- **Zinc**: Cool, professional feel
- **Gray**: Classic, timeless appearance
- **Slate**: Blue-tinted grays

## Dark Mode Implementation

### Framework-Specific Guides

- **Next.js**: `/docs/dark-mode/next`
- **Vite**: `/docs/dark-mode/vite`
- **Astro**: `/docs/dark-mode/astro`
- **Remix**: `/docs/dark-mode/remix`

### Core Implementation Strategy

1. Check localStorage for existing theme preference
2. Fall back to system preference via `prefers-color-scheme` media query
3. Update meta theme-color dynamically based on mode

### Basic Detection Script

```javascript
if (
  localStorage.theme === 'dark' ||
  (!('theme' in localStorage) && window.matchMedia('(prefers-color-scheme: dark)').matches)
) {
}
```

## Core Concepts

### Component Ownership

Unlike traditional libraries, you **own the component code**. This means:

- Components live in your repository
- You can modify them directly
- No version conflicts with package updates
- Complete control over implementation details

### Composition Pattern

Components use a composition pattern with subcomponents:

```tsx
<Dialog>
  <DialogTrigger>Open</DialogTrigger>
  <DialogContent>
    <DialogHeader>
      <DialogTitle>Title</DialogTitle>
      <DialogDescription>Description</DialogDescription>
    </DialogHeader>
    <DialogFooter>Footer</DialogFooter>
  </DialogContent>
</Dialog>
```

### Radix UI Foundation

Most components are built on Radix UI primitives, providing:

- Accessible by default (WAI-ARIA compliant)
- Unstyled base components
- Keyboard navigation support
- Focus management
- Screen reader compatibility

### The `asChild` Pattern

Many components support the `asChild` prop to compose with custom elements:

```tsx
<Button asChild>
  <Link href="/dashboard">Dashboard</Link>
</Button>
```

This renders your custom component with Button styling and behavior.

## Component Examples

### Button Component

**Installation:**

```bash
pnpm dlx shadcn@latest add button
```

**Usage:**

```tsx
import { Button } from '@/components/ui/button';

<Button variant="outline">Click me</Button>;
```

**Variants:**

- `default`: Standard filled button
- `outline`: Border-only styling
- `secondary`: Alternate filled style
- `ghost`: Minimal, text-only appearance
- `destructive`: Red styling for dangerous actions
- `link`: Text link appearance

**Sizes:**

- `default`: Standard size
- `sm`: Small buttons
- `lg`: Large buttons
- `icon`: Medium icon buttons (square)
- `icon-sm`: Small icon buttons (size-8)
- `icon-lg`: Large icon buttons (size-10)

**API:**

| Prop      | Type                                                  | Default   |
| --------- | ----------------------------------------------------- | --------- |
| `variant` | outline, ghost, destructive, secondary, link, default | "default" |
| `size`    | default, sm, lg, icon, icon-sm, icon-lg               | "default" |
| `asChild` | boolean                                               | false     |

**Examples:**

```tsx
<Button>Default Button</Button>
<Button variant="destructive">Delete</Button>
<Button variant="outline" size="lg">Large Outline</Button>
<Button size="icon">
  <PlusIcon />
</Button>

<Button asChild>
  <Link href="/login">Login</Link>
</Button>
```

### Card Component

**Installation:**

```bash
pnpm dlx shadcn@latest add card
```

**Structure:**

- `Card`: Main wrapper
- `CardHeader`: Top section
- `CardTitle`: Primary heading
- `CardDescription`: Supplementary text
- `CardAction`: Interactive header elements
- `CardContent`: Primary content area
- `CardFooter`: Bottom section

**Usage:**

```tsx
import {
  Card,
  CardHeader,
  CardTitle,
  CardDescription,
  CardAction,
  CardContent,
  CardFooter,
} from '@/components/ui/card';

<Card>
  <CardHeader>
    <CardTitle>Card Title</CardTitle>
    <CardDescription>Card Description</CardDescription>
    <CardAction>Card Action</CardAction>
  </CardHeader>
  <CardContent>
    <p>Card Content</p>
  </CardContent>
  <CardFooter>
    <p>Card Footer</p>
  </CardFooter>
</Card>;
```

### Dialog Component

**Installation:**

```bash
pnpm dlx shadcn@latest add dialog
```

**Description:** A window overlaid on either the primary window or another dialog window, rendering the content underneath inert.

**Structure:**

- `Dialog`: Root container
- `DialogTrigger`: Element that opens the dialog
- `DialogContent`: Main dialog container
- `DialogHeader/DialogFooter`: Structural sections
- `DialogTitle`: Heading element
- `DialogDescription`: Explanatory text
- `DialogClose`: Button to dismiss the dialog

**Usage:**

```tsx
import {
  Dialog,
  DialogContent,
  DialogDescription,
  DialogHeader,
  DialogTitle,
  DialogTrigger,
} from '@/components/ui/dialog';

<Dialog>
  <DialogTrigger asChild>
    <Button variant="outline">Open Dialog</Button>
  </DialogTrigger>
  <DialogContent className="sm:max-w-[425px]">
    <DialogHeader>
      <DialogTitle>Edit profile</DialogTitle>
      <DialogDescription>Make changes to your profile here.</DialogDescription>
    </DialogHeader>
    <div className="grid gap-4 py-4"></div>
  </DialogContent>
</Dialog>;
```

**Important Constraint:** When using Dialog within Context Menu or Dropdown Menu, the Dialog must wrap the menu component rather than appearing nested within menu items.

### Select Component

**Installation:**

```bash
pnpm dlx shadcn@latest add select
```

**Description:** Displays a list of options for the user to pick from—triggered by a button.

**Components:**

- `Select`: Root container
- `SelectTrigger`: The button that opens the dropdown
- `SelectValue`: Displays the current selection or placeholder text
- `SelectContent`: Container for dropdown options
- `SelectItem`: Individual selectable options
- `SelectGroup`: Groups related items with labels

**Usage:**

```tsx
import {
  Select,
  SelectContent,
  SelectItem,
  SelectTrigger,
  SelectValue,
} from '@/components/ui/select';

<Select>
  <SelectTrigger className="w-[180px]">
    <SelectValue placeholder="Theme" />
  </SelectTrigger>
  <SelectContent>
    <SelectItem value="light">Light</SelectItem>
    <SelectItem value="dark">Dark</SelectItem>
    <SelectItem value="system">System</SelectItem>
  </SelectContent>
</Select>;
```

**Grouped Example:**

```tsx
<Select>
  <SelectTrigger>
    <SelectValue placeholder="Select timezone" />
  </SelectTrigger>
  <SelectContent>
    <SelectGroup>
      <SelectLabel>North America</SelectLabel>
      <SelectItem value="est">Eastern Standard Time (EST)</SelectItem>
      <SelectItem value="cst">Central Standard Time (CST)</SelectItem>
    </SelectGroup>
    <SelectGroup>
      <SelectLabel>Europe</SelectLabel>
      <SelectItem value="gmt">Greenwich Mean Time (GMT)</SelectItem>
      <SelectItem value="cet">Central European Time (CET)</SelectItem>
    </SelectGroup>
  </SelectContent>
</Select>
```

### Dropdown Menu Component

**Installation:**

```bash
pnpm dlx shadcn@latest add dropdown-menu
```

**Description:** Displays a menu to the user — such as a set of actions or functions — triggered by a button.

**Components:**

- `DropdownMenu`: Wrapper container
- `DropdownMenuTrigger`: Button that opens the menu
- `DropdownMenuContent`: Menu container with positioning
- `DropdownMenuItem`: Individual menu options
- `DropdownMenuLabel`: Section labels
- `DropdownMenuSeparator`: Visual dividers
- `DropdownMenuShortcut`: Keyboard shortcut display
- `DropdownMenuGroup`: Groups related items
- `DropdownMenuSub`: Nested submenu support
- `DropdownMenuCheckboxItem`: Checkbox variants
- `DropdownMenuRadioItem`: Radio button variants

**Basic Usage:**

```tsx
import {
  DropdownMenu,
  DropdownMenuContent,
  DropdownMenuItem,
  DropdownMenuLabel,
  DropdownMenuSeparator,
  DropdownMenuTrigger,
} from '@/components/ui/dropdown-menu';

<DropdownMenu>
  <DropdownMenuTrigger asChild>
    <Button variant="outline">Open</Button>
  </DropdownMenuTrigger>
  <DropdownMenuContent>
    <DropdownMenuLabel>My Account</DropdownMenuLabel>
    <DropdownMenuSeparator />
    <DropdownMenuItem>Profile</DropdownMenuItem>
    <DropdownMenuItem>Billing</DropdownMenuItem>
    <DropdownMenuItem>Settings</DropdownMenuItem>
  </DropdownMenuContent>
</DropdownMenu>;
```

**Checkboxes Pattern:**

```tsx
const [showBookmarks, setShowBookmarks] = useState(true)

<DropdownMenuCheckboxItem
  checked={showBookmarks}
  onCheckedChange={setShowBookmarks}
>
  Show Bookmarks
</DropdownMenuCheckboxItem>
```

**Radio Groups Pattern:**

```tsx
const [position, setPosition] = useState("bottom")

<DropdownMenuRadioGroup value={position} onValueChange={setPosition}>
  <DropdownMenuRadioItem value="top">Top</DropdownMenuRadioItem>
  <DropdownMenuRadioItem value="bottom">Bottom</DropdownMenuRadioItem>
</DropdownMenuRadioGroup>
```

**Dialog Integration:**
Use `modal={false}` on the DropdownMenu to allow dialogs triggered from menu items to display properly:

```tsx
<DropdownMenu modal={false}></DropdownMenu>
```

### Tabs Component

**Installation:**

```bash
pnpm dlx shadcn@latest add tabs
```

**Description:** Displays a set of layered sections of content—known as tab panels—that are displayed one at a time.

**Components:**

- `Tabs`: Root container
- `TabsList`: Container for tab triggers
- `TabsTrigger`: Individual clickable tab buttons
- `TabsContent`: Content panel for each tab

**Usage:**

```tsx
import { Tabs, TabsContent, TabsList, TabsTrigger } from '@/components/ui/tabs';

<Tabs defaultValue="account">
  <TabsList>
    <TabsTrigger value="account">Account</TabsTrigger>
    <TabsTrigger value="password">Password</TabsTrigger>
  </TabsList>
  <TabsContent value="account">
    <p>Account settings content</p>
  </TabsContent>
  <TabsContent value="password">
    <p>Password settings content</p>
  </TabsContent>
</Tabs>;
```

### Sonner (Toast) Component

**Installation:**

```bash
pnpm dlx shadcn@latest add sonner
```

**Note:** The original `Toast` component has been deprecated. Sonner is the recommended replacement.

**Description:** An opinionated toast component for React, built by emilkowalski\_.

**Setup:**

Add the Toaster component to your root layout:

```tsx
import { Toaster } from '@/components/ui/sonner';

export default function RootLayout({ children }) {
  return (
    <html lang="en">
      <body>
        <main>{children}</main>
        <Toaster />
      </body>
    </html>
  );
}
```

**Basic Usage:**

```tsx
import { toast } from 'sonner';

toast('Event has been created.');
```

**Toast Types:**

```tsx
toast('Default notification');
toast.success('Event has been created');
toast.info('Be at the area 10 minutes before the event time');
toast.warning('Event start time cannot be earlier than 8am');
toast.error('Event has not been created');
```

**Advanced Example:**

```tsx
toast('Event has been created', {
  description: 'Sunday, December 03, 2023 at 9:00 AM',
  action: {
    label: 'Undo',
    onClick: () => console.log('Undo'),
  },
});
```

**Promise Handling:**

```tsx
toast.promise(myAsyncFunction(), {
  loading: 'Loading...',
  success: (data) => `${data.name} has been created`,
  error: 'Error creating item',
});
```

**Recent Updates:** Now uses icons from **lucide** and integrates with `next-themes` for automatic theme support.

### Form Component

**Installation:**

```bash
pnpm dlx shadcn@latest add form
```

**Important Note:** The Form component is **no longer actively developed**. The documentation recommends using the `<Field />` component instead for new projects.

**Description:** A wrapper around `react-hook-form` that simplifies building accessible forms with React.

**Features:**

- Composable form field components
- Built-in validation using Zod
- Automatic accessibility features (ARIA attributes)
- Client and server-side validation support
- Type-safe form handling
- Integration with all Radix UI components

**Setup:**

1. Define Schema:

```typescript
import { z } from 'zod';

const formSchema = z.object({
  username: z.string().min(2, {
    message: 'Username must be at least 2 characters.',
  }),
});
```

2. Initialize Form:

```typescript
import { useForm } from 'react-hook-form';
import { zodResolver } from '@hookform/resolvers/zod';

const form = useForm<z.infer<typeof formSchema>>({
  resolver: zodResolver(formSchema),
  defaultValues: {
    username: '',
  },
});
```

**Important:** Since `FormField` uses controlled components, you must provide default values.

3. Build Form:

```tsx
import {
  Form,
  FormControl,
  FormDescription,
  FormField,
  FormItem,
  FormLabel,
  FormMessage,
} from '@/components/ui/form';
import { Input } from '@/components/ui/input';
import { Button } from '@/components/ui/button';

<Form {...form}>
  <form onSubmit={form.handleSubmit(onSubmit)} className="space-y-8">
    <FormField
      control={form.control}
      name="username"
      render={({ field }) => (
        <FormItem>
          <FormLabel>Username</FormLabel>
          <FormControl>
            <Input placeholder="shadcn" {...field} />
          </FormControl>
          <FormDescription>Your public display name.</FormDescription>
          <FormMessage />
        </FormItem>
      )}
    />
    <Button type="submit">Submit</Button>
  </form>
</Form>;
```

**Component Anatomy:**

```tsx
<Form>
  <FormField
    control={...}
    name="..."
    render={() => (
      <FormItem>
        <FormLabel />
        <FormControl>
          {/* Your form field */}
        </FormControl>
        <FormDescription />
        <FormMessage />
      </FormItem>
    )}
  />
</Form>
```

### Data Table Implementation

**Installation:**

```bash
pnpm dlx shadcn@latest add table
pnpm add @tanstack/react-table
```

**Description:** Powerful tables and datagrids built using TanStack Table. Rather than a pre-built component, shadcn/ui provides guidance for constructing custom tables.

**Project Structure:**

- `columns.tsx` - Column definitions (client component)
- `data-table.tsx` - DataTable wrapper component (client component)
- `page.tsx` - Data fetching and rendering (server component)

**Column Definitions:**

```typescript
import { ColumnDef } from '@tanstack/react-table';

type Payment = {
  id: string;
  amount: number;
  status: 'pending' | 'processing' | 'success' | 'failed';
  email: string;
};

export const columns: ColumnDef<Payment>[] = [
  {
    accessorKey: 'status',
    header: 'Status',
  },
  {
    accessorKey: 'email',
    header: 'Email',
  },
  {
    accessorKey: 'amount',
    header: 'Amount',
    cell: ({ row }) => {
      const amount = parseFloat(row.getValue('amount'));
      const formatted = new Intl.NumberFormat('en-US', {
        style: 'currency',
        currency: 'USD',
      }).format(amount);
      return <div className="font-medium">{formatted}</div>;
    },
  },
];
```

**Basic DataTable Component:**

```tsx
'use client';

import { ColumnDef, flexRender, getCoreRowModel, useReactTable } from '@tanstack/react-table';
import {
  Table,
  TableBody,
  TableCell,
  TableHead,
  TableHeader,
  TableRow,
} from '@/components/ui/table';

interface DataTableProps<TData, TValue> {
  columns: ColumnDef<TData, TValue>[];
  data: TData[];
}

export function DataTable<TData, TValue>({ columns, data }: DataTableProps<TData, TValue>) {
  const table = useReactTable({
    data,
    columns,
    getCoreRowModel: getCoreRowModel(),
  });

  return (
    <div className="rounded-md border">
      <Table>
        <TableHeader>
          {table.getHeaderGroups().map((headerGroup) => (
            <TableRow key={headerGroup.id}>
              {headerGroup.headers.map((header) => (
                <TableHead key={header.id}>
                  {flexRender(header.column.columnDef.header, header.getContext())}
                </TableHead>
              ))}
            </TableRow>
          ))}
        </TableHeader>
        <TableBody>
          {table.getRowModel().rows?.length ? (
            table.getRowModel().rows.map((row) => (
              <TableRow key={row.id}>
                {row.getVisibleCells().map((cell) => (
                  <TableCell key={cell.id}>
                    {flexRender(cell.column.columnDef.cell, cell.getContext())}
                  </TableCell>
                ))}
              </TableRow>
            ))
          ) : (
            <TableRow>
              <TableCell colSpan={columns.length} className="h-24 text-center">
                No results.
              </TableCell>
            </TableRow>
          )}
        </TableBody>
      </Table>
    </div>
  );
}
```

**Features:**

- **Pagination**: Add `getPaginationRowModel` to table config
- **Sorting**: Enable with `getSortedRowModel` and `onSortingChange`
- **Filtering**: Integrate `getFilteredRowModel` with search inputs
- **Column Visibility**: Add `onColumnVisibilityChange` state
- **Row Selection**: Include checkbox column with `onRowSelectionChange`
- **Row Actions**: Implement dropdown menus accessing `row.original` data

## Recent Component Additions (October 2025)

Seven new components designed for everyday development:

### Spinner

Loading state indicator component.

### Kbd

Keyboard key display component for showing keyboard shortcuts.

### Button Group

Container for related buttons with consistent styling.

```tsx
import { Button } from '@/components/ui/button';
import { ButtonGroup } from '@/components/ui/button-group';

<ButtonGroup aria-label="Button group">
  <Button>Button 1</Button>
  <Button>Button 2</Button>
</ButtonGroup>;
```

**Split Button Pattern:**

```tsx
import { IconPlus } from '@tabler/icons-react';
import { ButtonGroup, ButtonGroupSeparator } from '@/components/ui/button-group';

<ButtonGroup>
  <Button variant="secondary">Button</Button>
  <ButtonGroupSeparator />
  <Button size="icon" variant="secondary">
    <IconPlus />
  </Button>
</ButtonGroup>;
```

### Input Group

Inputs enhanced with icons, buttons, labels, and more.

### Field

Comprehensive form component working with all form libraries. **Recommended over the Form component** for new projects.

```tsx
import { Field, FieldDescription, FieldGroup, FieldLabel, FieldSet } from '@/components/ui/field';
import { Input } from '@/components/ui/input';

<Field>
  <FieldLabel htmlFor="email">Email</FieldLabel>
  <Input id="email" type="email" />
  <FieldDescription>We'll never share your email.</FieldDescription>
</Field>;
```

### Item

Flexible flex container for lists, cards, and varied content.

### Empty

Empty state display component.

## Blocks

### What Are Blocks?

Blocks are pre-built, copy-paste components that serve as "building blocks for the web." They represent ready-made UI sections that developers can integrate directly into their projects.

**Philosophy:** "Clean, modern building blocks. Copy and paste into your apps. Works with all React frameworks. Open Source. Free forever."

### How to Use Blocks

```bash
npx shadcn add [block-name]
```

Browse available blocks at: https://ui.shadcn.com/blocks

**Customization:** Open blocks in v0 for modifications and customizations.

### Featured Blocks

- **Dashboard**: Sidebar navigation, interactive charts, data tables
- **Sidebar**: Collapsible sidebar that reduces to icons
- **Login Pages**: Multiple variations with different layouts
- **OTP & Calendar**: Specialized input and selection components

### Relationship to Components

Blocks are composite structures built from base shadcn/ui components. For example, the dashboard block combines:

- `Sidebar`
- `Chart`
- `DataTable`
- `Breadcrumb`
- `Separator`

You can use complete blocks or extract individual components for custom implementations.

## Best Practices

### 1. Component Ownership and Customization

**Do:**

- Treat installed components as starting points
- Modify component code directly to fit your needs
- Create variant extensions for project-specific use cases
- Document customizations for team awareness

**Don't:**

- Treat components as immutable library dependencies
- Hesitate to modify component internals
- Create wrappers when direct modification is simpler

### 2. Accessibility

**Do:**

- Use proper ARIA labels with `aria-label` attributes
- Associate labels with form controls using `htmlFor` and `id`
- Test keyboard navigation (Tab key support)
- Ensure proper focus management
- Maintain semantic HTML structure

**Example:**

```tsx
<ButtonGroup aria-label="Button group">
  <Button>Button 1</Button>
  <Button>Button 2</Button>
</ButtonGroup>

<Label htmlFor="email">Email address</Label>
<Input id="email" type="email" />
```

### 3. Type Safety

**Do:**

- Use TypeScript for all component implementations
- Define proper types for form schemas with Zod
- Leverage type inference from schemas
- Use generic types for reusable components like DataTable

**Example:**

```typescript
const formSchema = z.object({
  username: z.string().min(2),
});

type FormValues = z.infer<typeof formSchema>;

const form = useForm<FormValues>({
  resolver: zodResolver(formSchema),
  defaultValues: {
    username: '',
  },
});
```

### 4. Composition Patterns

**Do:**

- Use the `asChild` pattern for custom component integration
- Compose components hierarchically
- Keep composition shallow when possible
- Use proper subcomponent organization

**Example:**

```tsx
<DropdownMenu>
  <DropdownMenuTrigger asChild>
    <Button variant="outline">Open</Button>
  </DropdownMenuTrigger>
  <DropdownMenuContent>
    <DropdownMenuGroup>
      <DropdownMenuItem>Item 1</DropdownMenuItem>
    </DropdownMenuGroup>
  </DropdownMenuContent>
</DropdownMenu>
```

### 5. Form Handling

**Do:**

- Provide default values for all controlled form fields
- Use Zod for schema validation
- Leverage the Field component for new projects
- Implement proper error messaging

**Don't:**

- Use the deprecated Form component for new projects
- Omit default values from controlled components
- Skip validation

### 6. Performance Optimization

**Do:**

- Use Next.js Link component with `asChild` for client-side navigation
- Implement proper memoization for expensive calculations
- Use virtualization for long lists
- Optimize image loading

**Example:**

```tsx
import Link from 'next/link';

const PaginationLink = ({ href, ...props }) => (
  <PaginationItem>
    <Link href={href} {...props} />
  </PaginationItem>
);
```

### 7. Security

**Do:**

- Store registry tokens in `.env.local`
- Use environment variable substitution: `${VARIABLE_NAME}`
- Enforce HTTPS for registry URLs
- Implement token rotation (30-day expiration recommended)
- Log registry access for security auditing
- Implement rate limiting for API endpoints

**Example:**

```bash
REGISTRY_TOKEN=your_secret_token_here
API_KEY=your_api_key_here
```

```typescript
function generateToken() {
  const token = crypto.randomBytes(32).toString('hex');
  const expiresAt = new Date(Date.now() + 30 * 24 * 60 * 60 * 1000);
  return { token, expiresAt };
}

async function logAccess(request: Request, component: string, userId: string) {
  await db.accessLog.create({
    timestamp: new Date(),
    userId,
    component,
    ip: request.ip,
    userAgent: request.headers['user-agent'],
  });
}
```

```typescript
import rateLimit from 'express-rate-limit';

const limiter = rateLimit({
  windowMs: 15 * 60 * 1000,
  max: 100,
});

app.use('/registry', limiter);
```

### 8. Theming

**Do:**

- Use CSS variables for theming (recommended)
- Follow the background/foreground pairing convention
- Use oklch color format for perceptually uniform colors
- Define dark mode variants for all custom colors
- Choose base colors that match your design aesthetic

**Don't:**

- Change `baseColor` or `cssVariables` after initialization
- Mix theming approaches (variables vs utilities) inconsistently

## Common Gotchas and Pitfalls

### 1. Components.json Immutable Settings

**Problem:** Some settings cannot be changed after initialization.

**Immutable Settings:**

- `style`
- `tailwind.baseColor`
- `tailwind.cssVariables`

**Solution:** Plan these settings carefully during initialization or regenerate the project configuration.

### 2. Dialog Nesting with Menus

**Problem:** Dialogs don't work properly when nested inside DropdownMenu or ContextMenu items.

**Solution:** Use `modal={false}` on the DropdownMenu, or wrap the menu component with the Dialog instead of nesting Dialog inside menu items.

```tsx
<DropdownMenu modal={false}>
  <DropdownMenuItem>
    <Dialog></Dialog>
  </DropdownMenuItem>
</DropdownMenu>
```

### 3. Form Default Values

**Problem:** Controlled form fields break without default values.

**Why:** `FormField` uses controlled components which require initial values.

**Solution:** Always provide `defaultValues` in `useForm`:

```typescript
const form = useForm({
  defaultValues: {
    username: '',
    email: '',
  },
});
```

### 4. Button Cursor Styling

**Problem:** Tailwind v4 changed button cursors from pointer to default.

**Solution:** Add custom CSS to restore pointer behavior:

```css
button {
  cursor: pointer;
}
```

### 5. Next.js Link Integration

**Problem:** Using regular `<a>` tags in pagination or navigation components prevents client-side navigation.

**Solution:** Use Next.js Link with the component:

```diff
+ import Link from "next/link"

- type PaginationLinkProps = ... & React.ComponentProps<"a">
+ type PaginationLinkProps = ... & React.ComponentProps<typeof Link>

const PaginationLink = ({...props }) => (
  <PaginationItem>
-   <a>
+   <Link>
      ...
-   </a>
+   </Link>
)
```

### 6. Toast Component Deprecation

**Problem:** Using the deprecated Toast component.

**Solution:** Use Sonner instead:

```bash
pnpm dlx shadcn@latest add sonner
```

### 7. Icon Spacing in Buttons

**Note:** Icon spacing is automatically adjusted based on button size. Don't manually add spacing classes.

### 8. Input OTP Pattern Changes

**Problem:** Using the old render props pattern for InputOTPSlot.

**Solution:** Use the composition pattern with context:

```diff
- import { OTPInput, SlotProps } from "input-otp"
+ import { OTPInput, OTPInputContext } from "input-otp"

const InputOTPSlot = React.forwardRef<
  React.ElementRef<"div">,
-  SlotProps & React.ComponentPropsWithoutRef<"div">
- >(({ char, hasFakeCaret, isActive, className, ...props }, ref) => {
+  React.ComponentPropsWithoutRef<"div"> & { index: number }
+ >(({ index, className, ...props }, ref) => {
+  const inputOTPContext = React.useContext(OTPInputContext)
+  const { char, hasFakeCaret, isActive } = inputOTPContext.slots[index]
```

### 9. Registry Authentication

**Problem:** Authentication headers not being sent to private registries.

**Solution:** Use proper header configuration with environment variables:

```json
{
  "registries": {
    "@private": {
      "url": "https://registry.company.com/{name}.json",
      "headers": {
        "Authorization": "Bearer ${REGISTRY_TOKEN}"
      }
    }
  }
}
```

### 10. Breadcrumb Router Integration

**Problem:** Breadcrumbs using plain anchor tags instead of router links.

**Solution:** Use `asChild` pattern with your router's Link component:

```tsx
import Link from 'next/link';

<BreadcrumbLink asChild>
  <Link href="/">Home</Link>
</BreadcrumbLink>;
```

## Anti-Patterns

### 1. Wrapping Components Instead of Modifying

**Anti-pattern:**

```tsx
const MyCustomButton = ({ children, ...props }) => {
  return (
    <Button {...props} className={`my-custom-class ${props.className}`}>
      <Icon />
      {children}
    </Button>
  );
};
```

**Better approach:**
Directly modify the Button component file to add your custom variant or icon behavior.

### 2. Treating Components as Package Dependencies

**Anti-pattern:**
Avoiding modifications to component code because they feel like "library code."

**Better approach:**
Remember you own the components. Modify them directly to fit your needs.

### 3. Skipping Default Form Values

**Anti-pattern:**

```typescript
const form = useForm({
  resolver: zodResolver(schema),
});
```

**Better approach:**

```typescript
const form = useForm({
  resolver: zodResolver(schema),
  defaultValues: {
    field1: '',
    field2: false,
  },
});
```

### 4. Manual Color Class Application

**Anti-pattern:**

```tsx
<div className="bg-zinc-950 dark:bg-white">
```

**Better approach (with CSS variables):**

```tsx
<div className="bg-background">
```

### 5. Not Using the asChild Pattern

**Anti-pattern:**

```tsx
<Button onClick={() => router.push('/dashboard')}>Dashboard</Button>
```

**Better approach:**

```tsx
<Button asChild>
  <Link href="/dashboard">Dashboard</Link>
</Button>
```

### 6. Hardcoding Environment Variables

**Anti-pattern:**

```json
{
  "registries": {
    "@private": {
      "headers": {
        "Authorization": "Bearer abc123secrettoken"
      }
    }
  }
}
```

**Better approach:**

```json
{
  "registries": {
    "@private": {
      "headers": {
        "Authorization": "Bearer ${REGISTRY_TOKEN}"
      }
    }
  }
}
```

### 7. Using Deprecated Components

**Anti-pattern:**

```bash
pnpm dlx shadcn@latest add toast
pnpm dlx shadcn@latest add form
```

**Better approach:**

```bash
pnpm dlx shadcn@latest add sonner
```

Use the Field component instead of Form for new projects.

## Changelog Highlights

### October 2025 - Major Component Release

**Seven New Components:**

- Spinner - Loading indicators
- Kbd - Keyboard shortcuts display
- Button Group - Related button containers
- Input Group - Enhanced input fields
- Field - Form component (replaces Form)
- Item - Flexible container component
- Empty - Empty state displays

**Framework Support:**

- Works with Radix, Base UI, React Aria, and others
- Framework-agnostic approach

### August 2025 - CLI 3.0

**Namespaced Registries:**

- Support for `@registry/name` format
- Private registry support with authentication
- Improved search and discovery commands

**Breaking Changes:**

- `fetchRegistry` → `getRegistry` (programmatic API)
- No changes needed for components.json files

### February 2025 - Modern Framework Support

**Tailwind v4 Support:**

- New `@theme` directive
- `data-slot` attributes for styling
- Enhanced CSS variable handling

**React 19 Support:**

- Full compatibility with React 19
- Updated type definitions

### December 2024 - Monorepo Improvements

**Better Monorepo Support:**

- Easier component installation across multiple projects
- Improved import path management
- Better configuration sharing

## Version Information

- **Latest Release**: v3.5.0 (October 23, 2025)
- **Repository Stats**:
  - 100,000+ GitHub stars
  - 7,200+ forks
  - 396 contributors
  - 62 releases
  - 1,127 commits on main

## Design Integration

### Figma Resources

**Paid Kits:**

1. **shadcn/ui kit** by Matt Wierzbicki - Premium, always up-to-date UI kit optimized for design-to-dev handoff
2. **Shadcraft UI Kit** - Instant theming via tweakcn, pro library with 550+ blocks
3. **shadcn/studio UI Kit** - 550+ blocks, 10+ templates, 20+ themes, AI code converter

**Free Kits:**

1. **shadcn/ui design system** by Pietro Schirano - Carefully crafted to match code implementation
2. **Obra shadcn/ui** by Obra Studio - Philosophy-aligned kit tracking v4, MIT licensed

**Features:**

- Customizable props, typography, and icons
- All components recreated in Figma
- Community-contributed resources
- Design-to-code workflow integration

## Advanced Patterns

### Custom Registry Creation

Create your own component registry:

**1. Create registry.json:**

```json
{
  "$schema": "https://ui.shadcn.com/schema/registry-item.json",
  "name": "custom-style",
  "type": "registry:style",
  "dependencies": ["@tabler/icons-react"],
  "registryDependencies": ["login-01", "calendar"],
  "cssVars": {
    "theme": {
      "font-sans": "Inter, sans-serif"
    },
    "light": {
      "brand": "20 14.3% 4.1%"
    },
    "dark": {
      "brand": "20 14.3% 4.1%"
    }
  }
}
```

**2. Build registry:**

```bash
pnpm dlx shadcn@latest build --output ./public/registry
```

**3. Configure in components.json:**

```json
{
  "registries": {
    "@myregistry": "https://mysite.com/registry/{name}.json"
  }
}
```

### Custom Style Creation

Create a completely new style from scratch:

```json
{
  "$schema": "https://ui.shadcn.com/schema/registry-item.json",
  "extends": "none",
  "name": "new-style",
  "type": "registry:style",
  "dependencies": ["tailwind-merge", "clsx"],
  "registryDependencies": [
    "utils",
    "https://example.com/r/button.json",
    "https://example.com/r/input.json"
  ],
  "cssVars": {
    "theme": {
      "font-sans": "Inter, sans-serif"
    },
    "light": {
      "main": "#88aaee",
      "bg": "#dfe5f2",
      "border": "#000",
      "text": "#000",
      "ring": "#000"
    },
    "dark": {
      "main": "#88aaee",
      "bg": "#272933",
      "border": "#000",
      "text": "#e6e6e6",
      "ring": "#fff"
    }
  }
}
```

### Multi-Registry Stability Levels

Organize registries by stability:

```json
{
  "@stable": "https://registry.company.com/stable/{name}.json",
  "@latest": "https://registry.company.com/beta/{name}.json",
  "@experimental": "https://registry.company.com/experimental/{name}.json"
}
```

### Plugin Integration

Include Tailwind CSS plugins:

```json
{
  "$schema": "https://ui.shadcn.com/schema/registry-item.json",
  "name": "custom-plugin",
  "type": "registry:item",
  "css": {
    "@plugin \"@tailwindcss/typography\"": {},
    "@plugin \"foo\"": {}
  }
}
```

**Combined with imports:**

```json
{
  "css": {
    "@import \"tailwindcss\"": {},
    "@import url(\"https://fonts.googleapis.com/css2?family=Inter:wght@400;500;600&display=swap\")": {},
    "@plugin \"@tailwindcss/typography\"": {},
    "@plugin \"tw-animate-css\"": {},
    "@layer base": {
      "body": {
        "font-family": "Inter, sans-serif"
      }
    }
  }
}
```

## Error Handling

### Form Validation

```typescript
const formSchema = z.object({
  email: z.string().email({
    message: 'Please enter a valid email address.',
  }),
  password: z.string().min(8, {
    message: 'Password must be at least 8 characters.',
  }),
});

type FormState = {
  values?: z.infer<typeof formSchema>;
  errors: null | Partial<Record<keyof z.infer<typeof formSchema>, string[]>>;
  success: boolean;
};
```

### Registry Authentication Errors

```typescript
if (!token) {
  return NextResponse.json(
    {
      error: 'Unauthorized',
      message: 'Authentication required. Set REGISTRY_TOKEN in your .env.local file',
    },
    { status: 401 }
  );
}

if (isExpiredToken(token)) {
  return NextResponse.json(
    {
      error: 'Unauthorized',
      message: 'Token expired. Request a new token at company.com/tokens',
    },
    { status: 401 }
  );
}

if (!hasTeamAccess(token, component)) {
  return NextResponse.json(
    {
      error: 'Forbidden',
      message: `Component '${component}' is restricted to the Design team`,
    },
    { status: 403 }
  );
}
```

### Token Validation

```typescript
interface TemporaryToken {
  token: string;
  expiresAt: Date;
  scope: string[];
}

async function validateTemporaryToken(token: string) {
  const tokenData = await getTokenData(token);

  if (!tokenData) return false;
  if (new Date() > tokenData.expiresAt) return false;

  return true;
}
```

## Performance Considerations

### 1. Client-Side Navigation

Use framework-specific routing components with `asChild`:

```tsx
import Link from 'next/link';

<Button asChild>
  <Link href="/dashboard">Dashboard</Link>
</Button>;
```

### 2. Data Table Optimization

- Use virtualization for large datasets
- Implement server-side pagination for very large tables
- Memoize expensive cell formatters
- Use proper TypeScript types for type safety

### 3. Form Performance

- Use controlled components with proper default values
- Implement field-level validation instead of form-level when possible
- Debounce async validation
- Use `mode: "onBlur"` for less frequent validation

### 4. Chart Accessibility

Enable accessibility features without performance penalty:

```tsx
<LineChart accessibilityLayer />
```

### 5. Image Optimization

When using images in components like AspectRatio:

```tsx
<AspectRatio ratio={16 / 9}>
  <Image src="..." alt="Image" className="rounded-md object-cover" loading="lazy" />
</AspectRatio>
```

## Security Considerations

### 1. Token Management

- **Generate secure tokens**: Use `crypto.randomBytes(32)`
- **Set expiration**: 30-day maximum recommended
- **Rotate regularly**: Implement automatic rotation
- **Store securely**: Never commit to version control

```typescript
function generateToken() {
  const token = crypto.randomBytes(32).toString('hex');
  const expiresAt = new Date(Date.now() + 30 * 24 * 60 * 60 * 1000);
  return { token, expiresAt };
}
```

### 2. Access Logging

Track all registry access for security auditing:

```typescript
async function logAccess(request: Request, component: string, userId: string) {
  await db.accessLog.create({
    timestamp: new Date(),
    userId,
    component,
    ip: request.ip,
    userAgent: request.headers['user-agent'],
  });
}
```

### 3. Rate Limiting

Protect against abuse and DoS attacks:

```typescript
import rateLimit from 'express-rate-limit';

const limiter = rateLimit({
  windowMs: 15 * 60 * 1000,
  max: 100,
});

app.use('/registry', limiter);
```

### 4. HTTPS Enforcement

Always use HTTPS for registry URLs:

```json
{
  "registries": {
    "@secure": "https://registry.example.com/{name}.json",
    "@insecure": "http://registry.example.com/{name}.json"
  }
}
```

### 5. Environment Variables

Store all sensitive data in environment variables:

```bash
REGISTRY_TOKEN=your_secret_token_here
API_KEY=your_api_key_here
WORKSPACE_ID=your_workspace_id
```

Reference with `${VARIABLE_NAME}` syntax in configuration.

### 6. Multi-Factor Authentication

For enterprise registries with complex security:

```json
{
  "@enterprise": {
    "url": "https://api.enterprise.com/v2/registry/{name}",
    "headers": {
      "Authorization": "Bearer ${ACCESS_TOKEN}",
      "X-API-Key": "${API_KEY}",
      "X-Workspace-Id": "${WORKSPACE_ID}"
    },
    "params": {
      "version": "latest"
    }
  }
}
```

## Migration Notes

### From Toast to Sonner

The Toast component is deprecated. Migrate to Sonner:

**Before:**

```tsx
import { useToast } from '@/components/ui/toast';

const { toast } = useToast();
toast({
  title: 'Success',
  description: 'Item created',
});
```

**After:**

```tsx
import { toast } from 'sonner';

toast('Item created', {
  description: 'Successfully created new item',
});
```

### From Form to Field

The Form component is in maintenance mode. Use Field for new projects:

**Before (Form):**

```tsx
<FormField
  control={form.control}
  name="email"
  render={({ field }) => (
    <FormItem>
      <FormLabel>Email</FormLabel>
      <FormControl>
        <Input {...field} />
      </FormControl>
      <FormMessage />
    </FormItem>
  )}
/>
```

**After (Field):**

```tsx
<Field>
  <FieldLabel htmlFor="email">Email</FieldLabel>
  <Input id="email" type="email" />
  <FieldDescription>We'll never share your email.</FieldDescription>
</Field>
```

### Tailwind CSS v4 Migration

Update your configuration for Tailwind v4:

1. Leave `tailwind.config` blank in components.json
2. Use `@theme` directive for CSS variables
3. Update to `data-slot` attributes for component styling
4. Review color format changes (oklch support)

## Code Examples Collection

### Login Form Example

```tsx
import { Button } from '@/components/ui/button';
import {
  Card,
  CardContent,
  CardDescription,
  CardFooter,
  CardHeader,
  CardTitle,
} from '@/components/ui/card';
import { Input } from '@/components/ui/input';
import { Label } from '@/components/ui/label';

export function LoginForm() {
  return (
    <Card className="w-full max-w-sm">
      <CardHeader>
        <CardTitle className="text-2xl">Login</CardTitle>
        <CardDescription>Enter your email below to login to your account.</CardDescription>
      </CardHeader>
      <CardContent className="grid gap-4">
        <div className="grid gap-2">
          <Label htmlFor="email">Email</Label>
          <Input id="email" type="email" placeholder="m@example.com" required />
        </div>
        <div className="grid gap-2">
          <Label htmlFor="password">Password</Label>
          <Input id="password" type="password" required />
        </div>
      </CardContent>
      <CardFooter>
        <Button className="w-full">Sign in</Button>
      </CardFooter>
    </Card>
  );
}
```

### Input with Button Pattern

```tsx
import { Button } from '@/components/ui/button';
import { Input } from '@/components/ui/input';

export function InputWithButton() {
  return (
    <div className="flex w-full max-w-sm items-center gap-2">
      <Input type="email" placeholder="Email" />
      <Button type="submit" variant="outline">
        Subscribe
      </Button>
    </div>
  );
}
```

### AspectRatio Example

```tsx
import { AspectRatio } from '@/components/ui/aspect-ratio';
import Image from 'next/image';

export function AspectRatioDemo() {
  return (
    <AspectRatio ratio={16 / 9}>
      <Image src="/placeholder.jpg" alt="Photo" className="rounded-md object-cover" fill />
    </AspectRatio>
  );
}
```

### Data Table with Sorting Example

```tsx
'use client';

import { useState } from 'react';
import {
  ColumnDef,
  SortingState,
  flexRender,
  getCoreRowModel,
  getSortedRowModel,
  useReactTable,
} from '@tanstack/react-table';
import { Button } from '@/components/ui/button';
import { ArrowUpDown } from 'lucide-react';

type Payment = {
  id: string;
  amount: number;
  status: 'pending' | 'processing' | 'success' | 'failed';
  email: string;
};

export const columns: ColumnDef<Payment>[] = [
  {
    accessorKey: 'email',
    header: ({ column }) => (
      <Button variant="ghost" onClick={() => column.toggleSorting(column.getIsSorted() === 'asc')}>
        Email
        <ArrowUpDown className="ml-2 h-4 w-4" />
      </Button>
    ),
  },
  {
    accessorKey: 'amount',
    header: 'Amount',
    cell: ({ row }) => {
      const amount = parseFloat(row.getValue('amount'));
      const formatted = new Intl.NumberFormat('en-US', {
        style: 'currency',
        currency: 'USD',
      }).format(amount);
      return <div className="font-medium">{formatted}</div>;
    },
  },
];

export function DataTable() {
  const [sorting, setSorting] = useState<SortingState>([]);
  const [data] = useState<Payment[]>([]);

  const table = useReactTable({
    data,
    columns,
    getCoreRowModel: getCoreRowModel(),
    getSortedRowModel: getSortedRowModel(),
    onSortingChange: setSorting,
    state: {
      sorting,
    },
  });

  return (
    <div className="rounded-md border">
      <Table>
        <TableHeader>
          {table.getHeaderGroups().map((headerGroup) => (
            <TableRow key={headerGroup.id}>
              {headerGroup.headers.map((header) => (
                <TableHead key={header.id}>
                  {flexRender(header.column.columnDef.header, header.getContext())}
                </TableHead>
              ))}
            </TableRow>
          ))}
        </TableHeader>
        <TableBody>
          {table.getRowModel().rows?.length ? (
            table.getRowModel().rows.map((row) => (
              <TableRow key={row.id}>
                {row.getVisibleCells().map((cell) => (
                  <TableCell key={cell.id}>
                    {flexRender(cell.column.columnDef.cell, cell.getContext())}
                  </TableCell>
                ))}
              </TableRow>
            ))
          ) : (
            <TableRow>
              <TableCell colSpan={columns.length} className="h-24 text-center">
                No results.
              </TableCell>
            </TableRow>
          )}
        </TableBody>
      </Table>
    </div>
  );
}
```

## References

### Official Resources

- **Documentation**: https://ui.shadcn.com
- **GitHub Repository**: https://github.com/shadcn-ui/ui
- **Radix UI Documentation**: https://www.radix-ui.com/docs/primitives
- **TanStack Table**: https://tanstack.com/table
- **Tailwind CSS**: https://tailwindcss.com
- **React Hook Form**: https://react-hook-form.com
- **Zod**: https://zod.dev

### Community Resources

- **GitHub Discussions**: https://github.com/shadcn-ui/ui/discussions
- **shadcn/ui Blocks**: https://ui.shadcn.com/blocks
- **v0.dev**: https://v0.dev (AI-powered UI generation)
- **Awesome shadcn/ui**: https://github.com/birobirobiro/awesome-shadcn-ui

### Related Libraries

- **Sonner**: https://sonner.emilkowal.ski (Toast notifications)
- **Lucide Icons**: https://lucide.dev (Icon library)
- **Class Variance Authority**: https://cva.style/docs
- **clsx**: https://github.com/lukeed/clsx
- **tailwind-merge**: https://github.com/dcastil/tailwind-merge

### Framework Guides

- **Next.js**: https://ui.shadcn.com/docs/installation/next
- **Vite**: https://ui.shadcn.com/docs/installation/vite
- **React Router**: https://ui.shadcn.com/docs/installation/react-router
- **Remix**: https://ui.shadcn.com/docs/installation/remix
- **Astro**: https://ui.shadcn.com/docs/installation/astro

---

**Last Research Date**: November 19, 2025
**Research Version**: Latest (v3.5.0)
**Researcher Note**: This research document is based on the official shadcn/ui documentation, GitHub repository, and Context7 library documentation as of November 2025. Always verify against current official sources for the most up-to-date information.
