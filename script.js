/**
 * MadnessInnsmouth Portfolio — JavaScript
 * Accessibility-focused navigation and enhancements.
 */

(function () {
    'use strict';

    // ===== Utility Functions =====

    function debounce(func, wait) {
        let timeout;
        return function executedFunction(...args) {
            const later = () => {
                clearTimeout(timeout);
                func(...args);
            };
            clearTimeout(timeout);
            timeout = setTimeout(later, wait);
        };
    }

    function prefersReducedMotion() {
        return window.matchMedia('(prefers-reduced-motion: reduce)').matches;
    }

    function safeFocus(element) {
        if (element && typeof element.focus === 'function') {
            element.focus();
        }
    }

    // ===== Main Navigation (Hamburger Toggle with Focus Trap) =====

    function initNavigation() {
        const navToggle = document.querySelector('.nav-toggle');
        const mainNavigation = document.getElementById('main-navigation');

        if (!navToggle || !mainNavigation) return;

        function handleFocusTrap(e) {
            const focusableElements = mainNavigation.querySelectorAll(
                'a[href], button:not([disabled])'
            );
            const firstElement = focusableElements[0];
            const lastElement = focusableElements[focusableElements.length - 1];

            if (e.key === 'Tab') {
                if (e.shiftKey) {
                    if (document.activeElement === firstElement) {
                        e.preventDefault();
                        lastElement.focus();
                    }
                } else {
                    if (document.activeElement === lastElement) {
                        e.preventDefault();
                        firstElement.focus();
                    }
                }
            }
        }

        function closeMenu() {
            navToggle.setAttribute('aria-expanded', 'false');
            mainNavigation.classList.remove('active');
            mainNavigation.removeEventListener('keydown', handleFocusTrap);
            safeFocus(navToggle);
        }

        function openMenu() {
            navToggle.setAttribute('aria-expanded', 'true');
            mainNavigation.classList.add('active');
            mainNavigation.addEventListener('keydown', handleFocusTrap);

            // Move focus to the first item inside the menu
            const firstFocusable = mainNavigation.querySelector('a[href], button:not([disabled])');
            if (firstFocusable) {
                setTimeout(() => safeFocus(firstFocusable), 100);
            }
        }

        // Toggle on hamburger click
        navToggle.addEventListener('click', function () {
            const isExpanded = navToggle.getAttribute('aria-expanded') === 'true';
            if (isExpanded) {
                closeMenu();
            } else {
                openMenu();
            }
        });

        // Close when clicking outside the nav
        document.addEventListener('click', function (event) {
            const isInsideNav = mainNavigation.contains(event.target);
            const isToggle = navToggle.contains(event.target);
            const isExpanded = navToggle.getAttribute('aria-expanded') === 'true';

            if (!isInsideNav && !isToggle && isExpanded) {
                closeMenu();
            }
        });

        // Close on Escape key
        document.addEventListener('keydown', function (event) {
            if (event.key === 'Escape' && mainNavigation.classList.contains('active')) {
                closeMenu();
            }
        });

        // Close when a same-page anchor link is followed (so the nav doesn't hang open)
        mainNavigation.querySelectorAll('a[href^="#"]').forEach(function (link) {
            link.addEventListener('click', function () {
                closeMenu();
            });
        });

        // Close and reset on resize (prevents stale open state)
        window.addEventListener('resize', debounce(function () {
            if (mainNavigation.classList.contains('active')) {
                closeMenu();
            }
        }, 250));
    }

    // ===== Apps Submenu Accordion =====

    function initAppsSubmenu() {
        const appsToggle = document.getElementById('apps-toggle');
        const appsPanel = document.getElementById('apps-submenu');

        if (!appsToggle || !appsPanel) return;

        appsToggle.addEventListener('click', function () {
            const isExpanded = appsToggle.getAttribute('aria-expanded') === 'true';
            const newState = !isExpanded;

            appsToggle.setAttribute('aria-expanded', newState.toString());
            appsPanel.classList.toggle('active', newState);

            // Move focus to the first app link when opening
            if (newState) {
                const firstLink = appsPanel.querySelector('a[href]');
                if (firstLink) {
                    setTimeout(() => safeFocus(firstLink), 50);
                }
            }
        });
    }

    // ===== General Accessibility Enhancements =====

    function initGeneralEnhancements() {
        // Update copyright year automatically
        const currentYearElement = document.getElementById('current-year');
        if (currentYearElement) {
            currentYearElement.textContent = new Date().getFullYear().toString();
        }

        // Ensure all external links have rel="noopener noreferrer"
        document.querySelectorAll('a[target="_blank"]').forEach(function (link) {
            link.setAttribute('rel', 'noopener noreferrer');
        });

        // Smooth scroll for same-page anchor links (respects prefers-reduced-motion)
        if (!prefersReducedMotion()) {
            document.querySelectorAll('a[href^="#"]').forEach(function (anchor) {
                anchor.addEventListener('click', function (event) {
                    const targetId = this.getAttribute('href').substring(1);
                    const targetElement = document.getElementById(targetId);

                    if (targetElement) {
                        event.preventDefault();
                        targetElement.scrollIntoView({
                            behavior: 'smooth',
                            block: 'start'
                        });

                        // Move focus to the target so keyboard users don't get stranded
                        targetElement.setAttribute('tabindex', '-1');
                        setTimeout(() => safeFocus(targetElement), 500);
                    }
                });
            });
        }
    }

    // ===== Initialisation =====

    function init() {
        initNavigation();
        initAppsSubmenu();
        initGeneralEnhancements();
    }

    if (document.readyState === 'loading') {
        document.addEventListener('DOMContentLoaded', init);
    } else {
        init();
    }

}());
