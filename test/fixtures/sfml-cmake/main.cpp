// LiveNiro fixture: SFML + CMake. Planets orbit a sun; arrow keys steer a ship.
#include <SFML/Graphics.hpp>
#include <cmath>

int main() {
    sf::RenderWindow window(sf::VideoMode(720, 420), "LiveNiro SFML Orbits");
    window.setFramerateLimit(60);
    const sf::Color colors[] = {{255, 93, 143}, {255, 209, 102}, {6, 214, 160}, {76, 201, 240}};
    sf::CircleShape sun(34.f);
    sun.setOrigin(34.f, 34.f);
    sun.setPosition(360.f, 210.f);
    sun.setFillColor({255, 190, 60});
    sf::ConvexShape ship(3);
    ship.setPoint(0, {0.f, -14.f});
    ship.setPoint(1, {10.f, 12.f});
    ship.setPoint(2, {-10.f, 12.f});
    ship.setFillColor(sf::Color::White);
    sf::Vector2f pos(120.f, 330.f);
    sf::Clock clock;
    while (window.isOpen()) {
        sf::Event e;
        while (window.pollEvent(e))
            if (e.type == sf::Event::Closed) window.close();
        float t = clock.getElapsedTime().asSeconds();
        if (sf::Keyboard::isKeyPressed(sf::Keyboard::Left)) pos.x -= 5.f;
        if (sf::Keyboard::isKeyPressed(sf::Keyboard::Right)) pos.x += 5.f;
        if (sf::Keyboard::isKeyPressed(sf::Keyboard::Up)) pos.y -= 5.f;
        if (sf::Keyboard::isKeyPressed(sf::Keyboard::Down)) pos.y += 5.f;
        window.clear({20, 14, 40});
        for (int i = 0; i < 60; ++i) {  // stars
            sf::CircleShape s(1.2f);
            s.setPosition(std::fmod(i * 97.f, 720.f), std::fmod(i * 53.f + t * 8.f, 420.f));
            s.setFillColor({255, 255, 255, 120});
            window.draw(s);
        }
        window.draw(sun);
        for (int i = 0; i < 4; ++i) {
            float r = 70.f + i * 38.f, a = t * (1.4f - i * 0.25f) + i;
            sf::CircleShape orbit(r);
            orbit.setOrigin(r, r);
            orbit.setPosition(360.f, 210.f);
            orbit.setFillColor(sf::Color::Transparent);
            orbit.setOutlineColor({255, 255, 255, 30});
            orbit.setOutlineThickness(1.f);
            window.draw(orbit);
            sf::CircleShape p(9.f + i * 2.f);
            p.setOrigin(9.f + i * 2.f, 9.f + i * 2.f);
            p.setPosition(360.f + r * std::cos(a), 210.f + r * std::sin(a));
            p.setFillColor(colors[i]);
            window.draw(p);
        }
        ship.setPosition(pos);
        ship.setRotation(std::sin(t * 3.f) * 10.f);
        window.draw(ship);
        window.display();
    }
}
