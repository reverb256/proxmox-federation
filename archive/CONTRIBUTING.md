# Contributing to Neural Network Portfolio

Thank you for your interest in contributing to this VibeCoding methodology showcase. This project demonstrates consciousness-driven development with authentic data and 60fps performance optimization.

## Code of Conduct

### VibeCoding Principles
- **Classical Wisdom**: Ground technical decisions in philosophical principles
- **Democratic Values**: Respect privacy, user agency, and Canadian Charter rights
- **Authentic Expression**: Use only real data sources, never mock or placeholder content
- **Performance Excellence**: Maintain 60fps animations and optimal user experience
- **Cyberpunk Aesthetics**: Preserve the futuristic design language with meaning

## Getting Started

### Development Environment
```bash
# Clone the repository
git clone [repository-url]
cd portfolio

# Install dependencies
npm install

# Start development server
npm run dev

# Run performance tests
npm run lighthouse
```

### Project Structure
```
portfolio/
├── client/src/
│   ├── components/      # Reusable UI components
│   ├── pages/          # Route components
│   ├── hooks/          # Custom React hooks
│   └── styles/         # Global styles and themes
├── server/             # Express backend (if needed)
├── shared/             # Shared types and utilities
├── docs/               # Documentation files
└── .github/            # GitHub workflows and templates
```

## Contribution Guidelines

### Data Authenticity Requirements
- **Gaming Statistics**: Use actual Steam profile data, VRChat hours, platform analytics
- **Project Information**: Real deployment URLs, authentic performance metrics
- **Technology Experience**: Genuine skill assessments, not inflated claims
- **Performance Data**: Actual Lighthouse scores, real optimization results

### Code Quality Standards

#### TypeScript Requirements
```typescript
// Proper type definitions for all components
interface GamingExperienceProps {
  experience: {
    title: string;
    hours: string;        // Authentic gaming hours from Steam/VRChat
    platform: string;     // Real platforms used
    description: string;  // Genuine research descriptions
  };
}

// No any types allowed
const processData = (data: AuthenticProjectData): ProcessedData => {
  // Implementation with proper error handling
};
```

#### Performance Standards
- **60fps Animations**: All animations use transform/opacity for GPU acceleration
- **Bundle Size**: Monitor and optimize dependency weights
- **Lighthouse Scores**: Maintain 90+ performance, 95+ accessibility
- **Mobile Performance**: Test across devices and network conditions

#### Accessibility Requirements
- **WCAG AAA Compliance**: Exceed standard accessibility requirements
- **Screen Reader Support**: Proper ARIA labels and semantic HTML
- **Keyboard Navigation**: Full functionality without mouse
- **Reduced Motion**: Respect user preferences for animations

### Design System Compliance

#### Cyberpunk Aesthetic Guidelines
```css
/* Use established color spectrum variables */
.new-component {
  background: var(--spectrum-cyan);
  border: 1px solid var(--synthwave-blue);
  color: var(--text-primary);
}

/* GPU acceleration for all animations */
.animated-element {
  transform: translateZ(0);
  will-change: transform, opacity;
  transition: transform 0.3s cubic-bezier(0.4, 0, 0.2, 1);
}
```

#### Tech Humor Guidelines
- **Programming Jokes**: Include relevant humor in technology tooltips
- **Cultural References**: Cyberpunk and gaming culture appropriate
- **Professional Balance**: Maintain portfolio credibility while adding personality

### Git Workflow

#### Branch Naming
```bash
feature/performance-optimization
fix/tooltip-layering-issue
docs/deployment-guide-update
perf/animation-gpu-acceleration
```

#### Commit Messages
```bash
# Follow conventional commits format
feat(gaming): add authentic VRChat hours from Steam profile
fix(tooltips): resolve z-index layering with 99999 priority
perf(animations): implement GPU acceleration for 60fps
docs(readme): update deployment guide for Cloudflare CDN
```

#### Pull Request Process
1. **Fork Repository**: Create personal fork for development
2. **Feature Branch**: Work on focused, single-purpose branches
3. **Quality Checks**: Run tests, linting, and performance audits
4. **Documentation**: Update relevant docs and code comments
5. **Review Process**: Address feedback and maintain VibeCoding standards

### Testing Requirements

#### Performance Testing
```bash
# Run Lighthouse audit
npm run lighthouse

# Check bundle size
npm run analyze

# Test animations
npm run animation-test
```

#### Accessibility Testing
```bash
# Screen reader testing
npm run accessibility-audit

# Keyboard navigation verification
npm run keyboard-test

# Color contrast validation
npm run contrast-check
```

## Development Practices

### Component Development
```typescript
// Example: Performance-optimized gaming component
export function GamingExperience({ experience }: GamingExperienceProps) {
  // Use authentic data from Steam/VRChat APIs
  const authenticHours = useAuthenticGamingData(experience.platform);
  
  return (
    <div className="gpu-accelerated smooth-60fps holo-panel">
      <div className="gaming-stats">
        <span className="authentic-hours">{authenticHours}</span>
        <span className="platform-verified">{experience.platform}</span>
      </div>
    </div>
  );
}
```

### Animation Guidelines
```css
/* Preferred: GPU-accelerated transforms */
.good-animation {
  transform: translateX(100px) translateZ(0);
  opacity: 0.8;
  transition: transform 0.3s ease, opacity 0.3s ease;
}

/* Avoid: Layout-triggering properties */
.bad-animation {
  left: 100px;  /* Triggers layout */
  width: 200px; /* Triggers layout */
  height: 150px; /* Triggers layout */
}
```

### State Management
```typescript
// Use React Query for authentic data fetching
const { data: gamingStats } = useQuery({
  queryKey: ['gaming-stats'],
  queryFn: fetchAuthenticGamingData,
  staleTime: 1000 * 60 * 60, // 1 hour cache
});

// Local state for UI interactions
const [isHovered, setIsHovered] = useState(false);
```

## Security Guidelines

### Privacy Protection
- **No Tracking**: Avoid analytics or tracking scripts
- **Data Minimization**: Only collect necessary information
- **User Consent**: Respect browser preferences and settings
- **Secure Defaults**: Privacy-first configuration choices

### Dependency Security
```bash
# Regular security audits
npm audit --audit-level moderate

# Update dependencies safely
npm update --save

# Check for vulnerabilities
npx audit-ci --moderate
```

## Documentation Standards

### Code Documentation
```typescript
/**
 * Renders gaming experience with authentic Steam/VRChat data
 * Optimized for 60fps performance with GPU acceleration
 * 
 * @param experience - Verified gaming platform statistics
 * @returns JSX component with cyberpunk styling and tooltips
 */
export function GamingCard({ experience }: GameExperienceProps) {
  // Implementation with authentic data sources
}
```

### README Updates
- **Performance Metrics**: Include actual Lighthouse scores
- **Gaming Statistics**: Update with current authentic data
- **Deployment Status**: Real production URLs and status
- **Technology Stack**: Only technologies actually implemented

## Review Process

### Code Review Checklist
- [ ] **Authentic Data**: No mock or placeholder content
- [ ] **Performance**: 60fps animations verified
- [ ] **Accessibility**: WCAG AAA compliance maintained
- [ ] **VibeCoding**: Philosophical alignment checked
- [ ] **Security**: Privacy and democratic values respected
- [ ] **Documentation**: Code and README updated appropriately

### Performance Review
- [ ] **Lighthouse Score**: 90+ performance maintained
- [ ] **Bundle Size**: Impact assessed and optimized
- [ ] **Animation Quality**: 60fps across devices verified
- [ ] **Mobile Experience**: Responsive design tested
- [ ] **GitHub Pages**: Deployment compatibility confirmed

## Release Process

### Version Management
- **Semantic Versioning**: Major.Minor.Patch format
- **Changelog**: Document all changes with performance impact
- **Performance Tracking**: Lighthouse scores for each release
- **Gaming Data Updates**: Regular refresh of authentic statistics

### Deployment Pipeline
1. **CI Checks**: All tests and audits pass
2. **Performance Verification**: Lighthouse thresholds met
3. **Security Scan**: Vulnerability assessment complete
4. **GitHub Pages**: Automatic deployment to production
5. **Cloudflare**: CDN optimization applied

Thank you for contributing to this demonstration of consciousness-driven development with authentic data and philosophical grounding.