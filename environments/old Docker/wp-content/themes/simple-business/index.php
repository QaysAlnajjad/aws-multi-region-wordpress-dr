<?php get_header(); ?>

<main class="site-main">
    <div class="content-area">
        <?php if (have_posts()) : ?>
            <?php while (have_posts()) : the_post(); ?>
                <article class="post">
                    <header class="entry-header">
                        <h1 class="entry-title">
                            <a href="<?php the_permalink(); ?>"><?php the_title(); ?></a>
                        </h1>
                        <div class="entry-meta">
                            Posted on <?php echo get_the_date(); ?> by <?php the_author(); ?>
                        </div>
                    </header>
                    
                    <div class="entry-content">
                        <?php the_content(); ?>
                    </div>
                </article>
            <?php endwhile; ?>
        <?php else : ?>
            <article class="post">
                <header class="entry-header">
                    <h1 class="entry-title">Welcome to Our Business</h1>
                </header>
                <div class="entry-content">
                    <p>Thank you for visiting our website. We provide excellent services and have been in business for many years.</p>
                    
                    <div class="services-grid">
                        <div class="service-item">
                            <h3>Professional Services</h3>
                            <p>We offer top-quality professional services tailored to your business needs.</p>
                        </div>
                        <div class="service-item">
                            <h3>Expert Consultation</h3>
                            <p>Our experienced team provides expert consultation to help grow your business.</p>
                        </div>
                        <div class="service-item">
                            <h3>24/7 Support</h3>
                            <p>We're here to support you around the clock with dedicated customer service.</p>
                        </div>
                    </div>
                </div>
            </article>
        <?php endif; ?>
    </div>
</main>

<?php get_footer(); ?>