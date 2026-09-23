import Foundation

/// The mascot's fun facts. One is chosen per calendar day, so everyone sees the
/// same fact on the same day and it changes at midnight, like APOD itself.
///
/// Every entry is a well-established figure from NASA or ESA material, kept
/// deliberately conservative ("about", "more than") — the app never states a
/// number it could not back up.
enum SpaceFacts {
    static let all: [String] = [
        "A day on Venus is longer than its year: 243 Earth days to spin once, 225 to orbit the Sun.",
        "Sunlight takes about 8 minutes to reach Earth, so you always see the Sun slightly in the past.",
        "Olympus Mons on Mars is about 22 km tall, around two and a half times the height of Everest.",
        "Saturn is less dense than water. In a big enough bathtub, it would float.",
        "Apollo footprints on the Moon could last millions of years. There's no wind to blow them away.",
        "Jupiter's Great Red Spot is a storm wider than the whole Earth.",
        "About a million Earths could fit inside the Sun.",
        "The Space Station circles Earth every 90 minutes or so. Its crew sees about 16 sunrises a day.",
        "Space is silent. Sound needs air or another material to travel through.",
        "Dust storms on Mars can grow until they cover the entire planet for weeks.",
        "A year on Mercury lasts just 88 Earth days.",
        "Uranus spins on its side, with its axis tilted about 98 degrees.",
        "The Moon drifts about 3.8 cm farther from Earth every year.",
        "Sunsets on Mars glow blue, because fine dust scatters blue light toward the setting Sun.",
        "Neptune has the fastest winds in the solar system: more than 2,000 km/h.",
        "Voyager 1, launched in 1977, is the most distant object humans have ever built.",
        "A day on Jupiter lasts less than 10 hours, the shortest of any planet.",
        "Venus is the hottest planet, about 465 °C at the surface, though Mercury is closer to the Sun.",
        "The Sun holds about 99.8% of all the mass in the solar system.",
        "Stars twinkle because of Earth's air. Seen from space, they shine steadily.",
        "Saturn's rings are mostly water ice, and in most places only about 10 metres thick.",
        "The first Astronomy Picture of the Day went up on 16 June 1995. Astra can show you every one.",
        "Curiosity landed on Mars on 6 August 2012, and it has been exploring ever since.",
        "Perseverance landed in Jezero Crater on Mars on 18 February 2021, in what was once a lake.",
        "Saturn's moon Enceladus sprays jets of ice into space from an ocean hidden under its crust.",
        "The observable universe is about 93 billion light-years across.",
        "Mars has two small moons, Phobos and Deimos. Their names mean fear and dread.",
        "Pluto's bright heart is named Tombaugh Regio, after Clyde Tombaugh, who discovered Pluto.",
        "Halley's Comet comes back about every 76 years. Its next visit is in 2061.",
        "The Andromeda Galaxy's light left it 2.5 million years ago, before modern humans existed.",
        "A teaspoon of neutron star would weigh around a billion tonnes on Earth.",
    ]

    /// The fact for a given day, optionally stepped forward when the user asks
    /// for another one.
    static func fact(for date: Date, offset: Int = 0) -> String {
        let calendar = Calendar(identifier: .gregorian)
        let dayOfYear = calendar.ordinality(of: .day, in: .year, for: date) ?? 1
        let index = (dayOfYear - 1 + offset) % all.count
        return all[(index + all.count) % all.count]
    }
}
