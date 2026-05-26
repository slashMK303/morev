class Movie {
  final String id;
  final String title;
  final String description;
  final String genre;
  final List<String> genres; // Daftar genre untuk ditampilkan sebagai chips
  final String year;
  final double rating;
  final int reviewsCount;
  final String posterUrl; // URL poster film

  const Movie({
    required this.id,
    required this.title,
    required this.description,
    required this.genre,
    this.genres = const [],
    required this.year,
    required this.rating,
    required this.reviewsCount,
    required this.posterUrl,
  });

  // Data dummy film 
  static List<Movie> get mockMovies => const [
    Movie(
      id: '1',
      title: 'Forrest Gump',
      description:
          'The presidencies of Kennedy and Johnson, the Vietnam War, the Watergate scandal and other historical events unfold from the perspective of an Alabama man with an IQ of 75.',
      genre: 'Drama',
      genres: ['Drama', 'Romance'],
      year: '1994',
      rating: 4.8,
      reviewsCount: 243,
      posterUrl:
          'https://images.unsplash.com/photo-1594909122845-11baa439b7bf?q=80&w=200&auto=format&fit=crop',
    ),
    Movie(
      id: '2',
      title: 'Inception',
      description:
          'A thief who steals corporate secrets through the use of dream-sharing technology is given the inverse task of planting an idea.',
      genre: 'Sci-Fi',
      genres: ['Action', 'Sci-Fi', 'Thriller'],
      year: '2010',
      rating: 4.8,
      reviewsCount: 289,
      posterUrl:
          'https://images.unsplash.com/photo-1536440136628-849c177e76a1?q=80&w=200&auto=format&fit=crop',
    ),
    Movie(
      id: '3',
      title: 'Interstellar',
      description:
          'A team of explorers travel through a wormhole in space in an attempt to ensure humanity\'s survival.',
      genre: 'Sci-Fi',
      genres: ['Sci-Fi', 'Drama', 'Adventure'],
      year: '2014',
      rating: 4.7,
      reviewsCount: 267,
      posterUrl:
          'https://images.unsplash.com/photo-1451187580459-43490279c0fa?q=80&w=200&auto=format&fit=crop',
    ),
    Movie(
      id: '4',
      title: 'Pulp Fiction',
      description:
          'The lives of two mob hitmen, a boxer, a gangster and his wife, and a pair of diner bandits intertwine in four tales of violence and redemption.',
      genre: 'Crime',
      genres: ['Crime', 'Drama'],
      year: '1994',
      rating: 4.5,
      reviewsCount: 176,
      posterUrl:
          'https://images.unsplash.com/photo-1509281373149-e957c6296406?q=80&w=200&auto=format&fit=crop',
    ),
    Movie(
      id: '5',
      title: 'The Dark Knight',
      description:
          'When the menace known as the Joker wreaks havoc and chaos on the people of Gotham, Batman must accept one of the greatest psychological and physical tests of his ability to fight injustice.',
      genre: 'Action',
      genres: ['Action', 'Crime', 'Drama'],
      year: '2008',
      rating: 4.9,
      reviewsCount: 234,
      posterUrl:
          'https://images.unsplash.com/photo-1478760329108-5c3ed9d495a0?q=80&w=200&auto=format&fit=crop',
    ),
    Movie(
      id: '6',
      title: 'The Godfather',
      description:
          'The aging patriarch of an organized crime dynasty transfers control of his clandestine empire to his reluctant son.',
      genre: 'Crime',
      genres: ['Crime', 'Drama'],
      year: '1972',
      rating: 4.7,
      reviewsCount: 118,
      posterUrl:
          'https://images.unsplash.com/photo-1518709268805-4e9042af9f23?q=80&w=200&auto=format&fit=crop',
    ),
    Movie(
      id: '7',
      title: 'The Matrix',
      description:
          'A computer hacker learns from mysterious rebels about the true nature of his reality and his role in the war against its controllers.',
      genre: 'Action',
      genres: ['Action', 'Sci-Fi'],
      year: '1999',
      rating: 4.6,
      reviewsCount: 321,
      posterUrl:
          'https://images.unsplash.com/photo-1526374965328-7f61d4dc18c5?q=80&w=200&auto=format&fit=crop',
    ),
    Movie(
      id: '8',
      title: 'The Shawshank Redemption',
      description:
          'Two imprisoned men bond over a number of years, finding solace and eventual redemption through acts of common decency.',
      genre: 'Drama',
      genres: ['Drama'],
      year: '1994',
      rating: 4.8,
      reviewsCount: 153,
      posterUrl:
          'https://images.unsplash.com/photo-1512070673790-ee72b7f5c8b0?q=80&w=200&auto=format&fit=crop',
    ),
  ];
}
