<style>
.show, .years {
    display: flex;
    align-items: center;
     justify-content: space-around;
    margin-bottom: 1em;
}
.years {
    margin: 1em 0 2em;
}
</style>

<h2>
    Emisije od 2011 do 2019
</h2>

<div class="years">
    <strong>Idi na godinu:</strong> {% for jump_to_year in (2011..2019) %} <a href="#{{ jump_to_year }}">{{ jump_to_year }}</a> {% endfor %}
</div>

{% assign previous_show_year = '' %}

{% for show in site.static_files %}
{% if show.path contains 'emisije/gozba' %}

{% assign filename = show.path | split: 'emisije/gozba-' %}
{% assign show_year = filename[1] | date: "%Y" %}
{% assign show_date = filename[1] | date: "%d. %m. %Y." %}

{% if show_year != previous_show_year %}
{% assign previous_show_year = show_year %}

<hr />

<h3 id="{{show_year}}">Emisije iz {{ show_year }}</h3>
{% endif %}

<div class="show">
    <strong>Emisija od {{ show_date }}</strong>
    <audio controls preload="none">
    <source src="{{ site.baseurl }}{{ show.path }}" type="audio/mpeg">
    Your browser does not support the audio element.
    </audio>
    <a href="{{ site.baseurl }}{{ show.path }}" title="Preuzmi emisiju gozba od '{{ show_date }}' desnim klikom pa 'Save link as...'">
        <img src="download.png" alt="Preuzmi emisiju gozba od {{ show_date }}" />
    </a>

</div>

{% endif %}

{% endfor %}
