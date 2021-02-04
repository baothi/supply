document.onreadystatechange = function () {
    if (document.readyState === 'complete') {
        const docEl = document.documentElement;
        const header = document.querySelector('.header__wrapper');
        const dropdown = document.querySelector('.js-burger');
        const menu = document.querySelector('.header__nav-list');
        const slider = document.querySelector('.js_slider');
        const menuButtons = Array.from(document.querySelectorAll('.js-button'));
        const footerCloseIcon = document.querySelector('.js-footer__icon');
        lory(slider, { infinite: 1 });

        // Mobile menu

        function closeMobileMenu() {
            dropdown.classList.remove('is-active');
            menu.classList.remove('is-active');
        }

        dropdown.addEventListener('click', function(e) {
            e.stopPropagation();
        dropdown.classList.toggle('is-active');
        menu.classList.toggle('is-active');
    });

        menuButtons.forEach(function(button) {
            button.addEventListener('click', function() {
                closeMobileMenu()
            });
        })

        // Smooth scroll animation

        $('a').click(function() {
            $('html, body').animate({
                scrollTop: $( $(this).attr('href') ).offset().top - 30
            }, 500);
            closeMobileMenu();
            return false;
        });

        // Topbar style change on scroll

        window.onscroll = function () {
            var sTop = (this.pageYOffset || docEl.scrollTop)  - (docEl.clientTop || 0);
            const mq = window.matchMedia( "(min-width: 500px)" );

            if (mq.matches) {
                sTop = sTop - 50;
            }

            if (sTop > 625) {
                header.classList.add('no-bg');
                menu.classList.add('no-bg');
            } else {
                header.classList.remove('no-bg');
                menu.classList.remove('no-bg');
                if (sTop > 1) {
                    header.classList.add('with-shadow');
                } else {
                    header.classList.remove('with-shadow');
                }
            }
        };

        // Footer bar close

        footerCloseIcon.addEventListener('click', function(e){
            e.stopPropagation();
        document.querySelector('.footer__wrapper').style.display = 'none';
    });
    }
}