# Animation Library Reference

This document contains detailed animation examples and complete implementation code for Tailwind CSS v4 animations.

## Complete Animation Examples

### Fade In

```css
@theme {
  --animate-fade-in: fade-in 0.3s ease-out;

  @keyframes fade-in {
    0% {
      opacity: 0;
    }
    100% {
      opacity: 1;
    }
  }
}
```

**Usage:**

```html
<div class="animate-fade-in">Fades in</div>
```

### Fade In Scale

```css
@theme {
  --animate-fade-in-scale: fade-in-scale 0.3s ease-out;

  @keyframes fade-in-scale {
    0% {
      opacity: 0;
      transform: scale(0.95);
    }
    100% {
      opacity: 1;
      transform: scale(1);
    }
  }
}
```

**Usage:**

```html
<div class="animate-fade-in-scale">Fades and scales in</div>
```

### Slide In from Bottom

```css
@theme {
  --animate-slide-up: slide-up 0.4s ease-out;

  @keyframes slide-up {
    0% {
      opacity: 0;
      transform: translateY(20px);
    }
    100% {
      opacity: 1;
      transform: translateY(0);
    }
  }
}
```

**Usage:**

```html
<div class="animate-slide-up">Slides up while fading in</div>
```

### Spin

```css
@theme {
  --animate-spin: spin 1s linear infinite;

  @keyframes spin {
    to {
      transform: rotate(360deg);
    }
  }
}
```

**Usage:**

```html
<div class="animate-spin">
  <svg>...</svg>
</div>
```

### Pulse

```css
@theme {
  --animate-pulse: pulse 2s cubic-bezier(0.4, 0, 0.6, 1) infinite;

  @keyframes pulse {
    0%, 100% {
      opacity: 1;
    }
    50% {
      opacity: 0.5;
    }
  }
}
```

**Usage:**

```html
<div class="animate-pulse">Pulsing element</div>
```

### Bounce

```css
@theme {
  --animate-bounce: bounce 1s infinite;

  @keyframes bounce {
    0%, 100% {
      transform: translateY(-25%);
      animation-timing-function: cubic-bezier(0.8, 0, 1, 1);
    }
    50% {
      transform: translateY(0);
      animation-timing-function: cubic-bezier(0, 0, 0.2, 1);
    }
  }
}
```

**Usage:**

```html
<div class="animate-bounce">Bouncing element</div>
```

### Ping (Ripple Effect)

```css
@theme {
  --animate-ping: ping 1s cubic-bezier(0, 0, 0.2, 1) infinite;

  @keyframes ping {
    0% {
      transform: scale(1);
      opacity: 1;
    }
    75%, 100% {
      transform: scale(2);
      opacity: 0;
    }
  }
}
```

**Usage:**

```html
<div class="relative">
  <div class="absolute inset-0 animate-ping bg-blue-500 rounded-full"></div>
  <div class="relative bg-blue-600 rounded-full w-4 h-4"></div>
</div>
```

## Complex Animation Patterns

### Shake Animation

```css
@theme {
  --animate-shake: shake 0.5s ease-in-out;

  @keyframes shake {
    0%, 100% {
      transform: translateX(0);
    }
    10%, 30%, 50%, 70%, 90% {
      transform: translateX(-10px);
    }
    20%, 40%, 60%, 80% {
      transform: translateX(10px);
    }
  }
}
```

**Usage:**

```html
<div class="hover:animate-shake">Shake on hover</div>
```

### Wiggle

```css
@theme {
  --animate-wiggle: wiggle 1s ease-in-out infinite;

  @keyframes wiggle {
    0%, 100% {
      transform: rotate(-3deg);
    }
    50% {
      transform: rotate(3deg);
    }
  }
}
```

**Usage:**

```html
<div class="animate-wiggle">Wiggling element</div>
```

### Slide In from Directions

```css
@theme {
  --animate-slide-in-left: slide-in-left 0.4s ease-out;
  --animate-slide-in-right: slide-in-right 0.4s ease-out;
  --animate-slide-in-top: slide-in-top 0.4s ease-out;
  --animate-slide-in-bottom: slide-in-bottom 0.4s ease-out;

  @keyframes slide-in-left {
    0% {
      transform: translateX(-100%);
      opacity: 0;
    }
    100% {
      transform: translateX(0);
      opacity: 1;
    }
  }

  @keyframes slide-in-right {
    0% {
      transform: translateX(100%);
      opacity: 0;
    }
    100% {
      transform: translateX(0);
      opacity: 1;
    }
  }

  @keyframes slide-in-top {
    0% {
      transform: translateY(-100%);
      opacity: 0;
    }
    100% {
      transform: translateY(0);
      opacity: 1;
    }
  }

  @keyframes slide-in-bottom {
    0% {
      transform: translateY(100%);
      opacity: 0;
    }
    100% {
      transform: translateY(0);
      opacity: 1;
    }
  }
}
```

**Usage:**

```html
<div class="animate-slide-in-left">Slides from left</div>
<div class="animate-slide-in-right">Slides from right</div>
<div class="animate-slide-in-top">Slides from top</div>
<div class="animate-slide-in-bottom">Slides from bottom</div>
```

### Loading Dots

```css
@theme {
  --animate-dot-pulse: dot-pulse 1.4s infinite ease-in-out;

  @keyframes dot-pulse {
    0%, 80%, 100% {
      opacity: 0;
    }
    40% {
      opacity: 1;
    }
  }
}
```

**Usage:**

```html
<div class="flex gap-1">
  <div class="w-2 h-2 bg-blue-500 rounded-full animate-dot-pulse"></div>
  <div class="w-2 h-2 bg-blue-500 rounded-full animate-dot-pulse [animation-delay:0.2s]"></div>
  <div class="w-2 h-2 bg-blue-500 rounded-full animate-dot-pulse [animation-delay:0.4s]"></div>
</div>
```

## Complete Animation Library

Full implementation of all animations:

```css
@import 'tailwindcss';

@theme {
  --animate-spin: spin 1s linear infinite;
  --animate-ping: ping 1s cubic-bezier(0, 0, 0.2, 1) infinite;
  --animate-pulse: pulse 2s cubic-bezier(0.4, 0, 0.6, 1) infinite;
  --animate-bounce: bounce 1s infinite;

  --animate-fade-in: fade-in 0.3s ease-out;
  --animate-fade-out: fade-out 0.3s ease-in;
  --animate-fade-in-scale: fade-in-scale 0.3s ease-out;

  --animate-slide-up: slide-up 0.4s ease-out;
  --animate-slide-down: slide-down 0.4s ease-out;
  --animate-slide-left: slide-left 0.4s ease-out;
  --animate-slide-right: slide-right 0.4s ease-out;

  --animate-shake: shake 0.5s ease-in-out;
  --animate-wiggle: wiggle 1s ease-in-out infinite;

  @keyframes spin {
    to {
      transform: rotate(360deg);
    }
  }

  @keyframes ping {
    0% {
      transform: scale(1);
      opacity: 1;
    }
    75%, 100% {
      transform: scale(2);
      opacity: 0;
    }
  }

  @keyframes pulse {
    0%, 100% {
      opacity: 1;
    }
    50% {
      opacity: 0.5;
    }
  }

  @keyframes bounce {
    0%, 100% {
      transform: translateY(-25%);
      animation-timing-function: cubic-bezier(0.8, 0, 1, 1);
    }
    50% {
      transform: translateY(0);
      animation-timing-function: cubic-bezier(0, 0, 0.2, 1);
    }
  }

  @keyframes fade-in {
    0% {
      opacity: 0;
    }
    100% {
      opacity: 1;
    }
  }

  @keyframes fade-out {
    0% {
      opacity: 1;
    }
    100% {
      opacity: 0;
    }
  }

  @keyframes fade-in-scale {
    0% {
      opacity: 0;
      transform: scale(0.95);
    }
    100% {
      opacity: 1;
      transform: scale(1);
    }
  }

  @keyframes slide-up {
    0% {
      opacity: 0;
      transform: translateY(20px);
    }
    100% {
      opacity: 1;
      transform: translateY(0);
    }
  }

  @keyframes slide-down {
    0% {
      opacity: 0;
      transform: translateY(-20px);
    }
    100% {
      opacity: 1;
      transform: translateY(0);
    }
  }

  @keyframes slide-left {
    0% {
      opacity: 0;
      transform: translateX(20px);
    }
    100% {
      opacity: 1;
      transform: translateX(0);
    }
  }

  @keyframes slide-right {
    0% {
      opacity: 0;
      transform: translateX(-20px);
    }
    100% {
      opacity: 1;
      transform: translateX(0);
    }
  }

  @keyframes shake {
    0%, 100% {
      transform: translateX(0);
    }
    10%, 30%, 50%, 70%, 90% {
      transform: translateX(-10px);
    }
    20%, 40%, 60%, 80% {
      transform: translateX(10px);
    }
  }

  @keyframes wiggle {
    0%, 100% {
      transform: rotate(-3deg);
    }
    50% {
      transform: rotate(3deg);
    }
  }
}
```

## Advanced Techniques

### Animation with Variants

Animations work with all Tailwind variants:

```html
<div class="hover:animate-spin">Spins on hover</div>
<div class="focus:animate-pulse">Pulses on focus</div>
<div class="group-hover:animate-bounce">Bounces when parent hovered</div>
<div class="lg:animate-fade-in">Animates on large screens</div>
<div class="dark:animate-pulse">Pulses in dark mode</div>
```

### Combining Multiple Animations

Use arbitrary properties for complex animations:

```html
<div class="
  animate-fade-in
  [animation-delay:0.1s]
  [animation-fill-mode:both]
">
  Delayed fade in
</div>
```

### Staggered Animations

```html
<div class="space-y-4">
  <div class="animate-slide-up [animation-delay:0s]">Item 1</div>
  <div class="animate-slide-up [animation-delay:0.1s]">Item 2</div>
  <div class="animate-slide-up [animation-delay:0.2s]">Item 3</div>
  <div class="animate-slide-up [animation-delay:0.3s]">Item 4</div>
</div>
```

### Pausing Animations

```html
<div class="animate-spin hover:[animation-play-state:paused]">
  Pauses on hover
</div>
```

## Performance Considerations

1. **Use transform and opacity** - Hardware accelerated properties
2. **Avoid animating expensive properties** - Don't animate width, height, or layout properties
3. **Add will-change sparingly** - Only for known animations that need performance boost
4. **Test on low-end devices** - Ensure smooth performance across all devices
5. **Use CSS animations over JavaScript** - Better performance and smoother animations

## Accessibility

Respect user motion preferences:

```css
@media (prefers-reduced-motion: reduce) {
  * {
    animation-duration: 0.01ms !important;
    animation-iteration-count: 1 !important;
    transition-duration: 0.01ms !important;
  }
}
```
